// 网关双模式客户端 — 普通 TCP 与 mTLS 两种连接模式（SCI 论文实验协议，鸿蒙端）
// 链路: App --TCP/mTLS--> lscf_gateway (harmony_gateway.py) --UDP/LSCF--> ESP32
// 分帧: 换行分隔 JSON；请求-响应通过 requestId 匹配
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { GatewayRequest, GatewayResponse } from './GatewayModels';
import { MTLS_CA_CERT, MTLS_CLIENT_CERT, MTLS_CLIENT_KEY } from './TlsCredentials';

type ResponseResolver = (response: GatewayResponse) => void;
type ResponseRejecter = (reason: Error) => void;
type StatusListener = (status: string) => void;
type LogListener = (message: string) => void;

export class GatewayClient {
  private tcpSocket: socket.TCPSocket | null = null;
  private tlsSocket: socket.TLSSocket | null = null;
  private receiveBuffer: string = '';
  private pendingRequestId: string = '';
  private pendingResolve: ResponseResolver | null = null;
  private pendingReject: ResponseRejecter | null = null;
  private timeoutId: number = -1;
  private connected: boolean = false;
  private mtlsEnabled: boolean = false;
  private handshakeMs: number = 0;
  private statusListener: StatusListener | null = null;
  private logListener: LogListener | null = null;

  setOnStatus(listener: StatusListener): void {
    this.statusListener = listener;
  }

  setOnLog(listener: LogListener): void {
    this.logListener = listener;
  }

  isConnected(): boolean {
    return this.connected;
  }

  isMtlsEnabled(): boolean {
    return this.mtlsEnabled;
  }

  getHandshakeMs(): number {
    return this.handshakeMs;
  }

  async connect(host: string, port: number, useMtls: boolean = false): Promise<void> {
    this.disconnect();
    this.mtlsEnabled = useMtls;
    this.statusListener?.('正在连接 ' + host + ':' + port);
    const started = Date.now();
    try {
      if (useMtls) {
        await this.connectMtls(host, port);
      } else {
        await this.connectTcp(host, port);
      }
      this.handshakeMs = Date.now() - started;
      this.connected = true;
      this.statusListener?.((useMtls ? 'mTLS已连接 ' : 'TCP已连接 ') +
        host + ':' + port + '，建立耗时 ' + this.handshakeMs.toString() + ' ms');
    } catch (error) {
      const err = error as BusinessError;
      this.connected = false;
      this.statusListener?.('连接失败: ' + err.message);
      throw new Error(err.message);
    }
  }

  private async connectTcp(host: string, port: number): Promise<void> {
    const tcp = socket.constructTCPSocketInstance();
    this.tcpSocket = tcp;
    this.installTcpListeners(tcp);
    const options: socket.TCPConnectOptions = {
      address: { address: host, port: port },
      timeout: 5000
    };
    await tcp.connect(options);
  }

  private async connectMtls(host: string, port: number): Promise<void> {
    if (!MTLS_CA_CERT || !MTLS_CLIENT_CERT || !MTLS_CLIENT_KEY) {
      throw new Error('mTLS凭据未生成，请先运行generate_mtls_pki.py');
    }
    const tls = socket.constructTLSSocketInstance();
    this.tlsSocket = tls;
    this.installTlsListeners(tls);
    const secureOptions: socket.TLSSecureOptions = {
      ca: [MTLS_CA_CERT],
      cert: MTLS_CLIENT_CERT,
      key: MTLS_CLIENT_KEY,
      protocols: [socket.Protocol.TLSv12],
      useRemoteCipherPrefer: true
    };
    const options: socket.TLSConnectOptions = {
      address: { address: host, port: port },
      secureOptions: secureOptions
    };
    await tls.connect(options);
  }

  disconnect(): void {
    this.clearPending(new Error('连接已断开'));
    if (this.tcpSocket !== null) {
      this.tcpSocket.off('message');
      this.tcpSocket.off('error');
      this.tcpSocket.close();
      this.tcpSocket = null;
    }
    if (this.tlsSocket !== null) {
      this.tlsSocket.off('message');
      this.tlsSocket.off('error');
      this.tlsSocket.close();
      this.tlsSocket = null;
    }
    this.connected = false;
    this.receiveBuffer = '';
    this.statusListener?.('未连接');
  }

  sendRequest(request: GatewayRequest, timeoutMs: number = 3000): Promise<GatewayResponse> {
    return new Promise<GatewayResponse>((resolve: ResponseResolver, reject: ResponseRejecter) => {
      if (!this.connected) {
        reject(new Error('请先连接网关'));
        return;
      }
      if (this.pendingResolve !== null) {
        reject(new Error('上一请求尚未完成'));
        return;
      }
      this.pendingRequestId = request.requestId;
      this.pendingResolve = resolve;
      this.pendingReject = reject;
      this.timeoutId = setTimeout(() => {
        this.clearPending(new Error('等待网关响应超时'));
      }, timeoutMs);
      const line = JSON.stringify(request) + '\n';
      this.logListener?.('发送: ' + line.trim());
      if (this.mtlsEnabled && this.tlsSocket !== null) {
        this.tlsSocket.send(line).catch((error: BusinessError) => {
          this.clearPending(new Error('发送失败: ' + error.message));
        });
      } else if (this.tcpSocket !== null) {
        this.tcpSocket.send({ data: line }).catch((error: BusinessError) => {
          this.clearPending(new Error('发送失败: ' + error.message));
        });
      }
    });
  }

  private appendMessage(value: socket.SocketMessageInfo): void {
    const decoder = util.TextDecoder.create('utf-8');
    this.receiveBuffer += decoder.decodeToString(new Uint8Array(value.message));
    this.consumeLines();
  }

  private installTcpListeners(tcp: socket.TCPSocket): void {
    tcp.on('message', (value: socket.SocketMessageInfo) => this.appendMessage(value));
    tcp.on('error', (error: BusinessError) => this.onSocketError(error));
  }

  private installTlsListeners(tls: socket.TLSSocket): void {
    tls.on('message', (value: socket.SocketMessageInfo) => this.appendMessage(value));
    tls.on('error', (error: BusinessError) => this.onSocketError(error));
  }

  private onSocketError(error: BusinessError): void {
    this.connected = false;
    this.statusListener?.('连接异常: ' + error.message);
    this.clearPending(new Error(error.message));
  }

  private consumeLines(): void {
    let newline = this.receiveBuffer.indexOf('\n');
    while (newline >= 0) {
      const line = this.receiveBuffer.substring(0, newline).trim();
      this.receiveBuffer = this.receiveBuffer.substring(newline + 1);
      if (line.length > 0) {
        this.handleLine(line);
      }
      newline = this.receiveBuffer.indexOf('\n');
    }
  }

  private handleLine(line: string): void {
    this.logListener?.('接收: ' + line);
    try {
      const response = JSON.parse(line) as GatewayResponse;
      if (this.pendingResolve === null) {
        return;
      }
      if (response.requestId !== this.pendingRequestId) {
        this.logListener?.('忽略requestId不匹配的响应: ' + response.requestId);
        return;
      }
      const resolver = this.pendingResolve;
      this.resetPending();
      resolver(response);
    } catch (error) {
      this.clearPending(new Error('响应JSON解析失败'));
    }
  }

  private clearPending(error: Error): void {
    const rejecter = this.pendingReject;
    this.resetPending();
    rejecter?.(error);
  }

  private resetPending(): void {
    if (this.timeoutId >= 0) {
      clearTimeout(this.timeoutId);
    }
    this.timeoutId = -1;
    this.pendingRequestId = '';
    this.pendingResolve = null;
    this.pendingReject = null;
  }
}

export const gatewayClient = new GatewayClient();
