/**
 * IoT 设备通信服务层
 * 提供 TCP 数据收发、UDP 设备发现、自动重连、心跳保活
 *
 * 兼容: HarmonyOS API 12 ~ 26
 * 废弃 API 已全部替换为全新用法
 */
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

// ==================== 类型定义 ====================

/** 物联网设备数据结构 */
export interface IoTDeviceData {
  deviceName: string;
  data: string[];
  rawString: string;
  timestamp: number;
}

/** TCP 连接状态枚举 */
export enum TcpState {
  DISCONNECTED = '未连接',
  CONNECTING = '连接中...',
  CONNECTED = '已连接',
  RECONNECTING = '重连中...',
  ERROR = '连接异常',
}

/** 连接事件类型 */
export enum ConnectionEvent {
  STATE_CHANGE = 'stateChange',
  DATA_RECEIVED = 'dataReceived',
  ERROR = 'error',
  DEVICE_FOUND = 'deviceFound',
}

/** 事件监听器类型 */
type EventListener = (...args: Object[]) => void;

// ==================== 通信服务类 ====================

export class Server {
  // ---- TCP 状态 ----
  private tcpSocket: socket.TCPSocket | null = null;
  private _connectionStatus: string = TcpState.DISCONNECTED;
  tcpAddress: string = '';
  tcpPort: number = 80;
  inputText: string = '';
  sendResult: string = '';
  mass: string = '';

  // ---- UDP 状态 ----
  private udpSocket: socket.UDPSocket | null = null;
  udpPort: number = 5000;
  private isUdpListening: boolean = false;

  // ---- 重连机制 ----
  private shouldReconnect: boolean = false;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;
  private reconnectTimer: number = -1;
  private baseReconnectDelay: number = 1000; // 1s 起步

  // ---- 心跳 ----
  private heartbeatTimer: number = -1;
  private heartbeatInterval: number = 30000; // 30s
  private lastHeartbeatResponse: number = Date.now();

  // ---- 事件系统 ----
  private eventListeners: Map<string, EventListener[]> = new Map();

  // ---- 对外只读状态 ----
  get connectionStatus(): string {
    return this._connectionStatus;
  }

  constructor() {
    this.resetTcpSocket();
    this.resetUdpSocket();
  }

  // ==================== 事件系统 ====================

  /** 注册事件监听 */
  on(event: ConnectionEvent | string, listener: EventListener): void {
    const key = event.toString();
    if (!this.eventListeners.has(key)) {
      this.eventListeners.set(key, []);
    }
    this.eventListeners.get(key)!.push(listener);
  }

  /** 移除事件监听 */
  off(event: ConnectionEvent | string, listener?: EventListener): void {
    const key = event.toString();
    if (!listener) {
      this.eventListeners.delete(key);
      return;
    }
    const listeners = this.eventListeners.get(key);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index >= 0) {
        listeners.splice(index, 1);
      }
    }
  }

  /** 触发事件 */
  private emit(event: ConnectionEvent | string, ...data: Object[]): void {
    const key = event.toString();
    const listeners = this.eventListeners.get(key);
    if (listeners) {
      for (const listener of listeners) {
        try {
          listener(...data);
        } catch (e) {
          hilog.error(0x0000, 'Server', '事件回调异常: %{public}s', JSON.stringify(e));
        }
      }
    }
  }

  /** 更新连接状态并通知 */
  private setConnectionStatus(status: string): void {
    this._connectionStatus = status;
    this.emit(ConnectionEvent.STATE_CHANGE, status);
  }

  // ==================== Socket 工厂 ====================

  private resetTcpSocket(): void {
    try {
      if (this.tcpSocket) {
        this.tcpSocket.off('message');
        this.tcpSocket.off('error');
        this.tcpSocket.close();
      }
    } catch (_) { /* ignore */ }
    this.tcpSocket = socket.constructTCPSocketInstance();
  }

  private resetUdpSocket(): void {
    try {
      if (this.udpSocket) {
        this.udpSocket.off('message');
        this.udpSocket.close();
      }
    } catch (_) { /* ignore */ }
    this.udpSocket = socket.constructUDPSocketInstance();
  }

  // ==================== TCP 连接管理 ====================

  /**
   * 连接 TCP 设备
   * @param address IP 地址
   * @param port 端口号
   */
  TCPServer(address?: string, port?: number): void {
    if (address) this.tcpAddress = address;
    if (port) this.tcpPort = port;

    if (!this.tcpAddress || !this.tcpPort) {
      this.setConnectionStatus(TcpState.ERROR + ': 请输入IP和端口');
      return;
    }

    this.resetTcpSocket();
    this.setConnectionStatus(TcpState.CONNECTING);
    this.shouldReconnect = true;
    this.reconnectAttempts = 0;

    const targetAddr: socket.NetAddress = {
      address: this.tcpAddress,
      port: this.tcpPort,
    };

    const connectOpts: socket.TCPConnectOptions = {
      address: targetAddr,
      timeout: 5000,
    };

    // 先注册错误监听
    this.tcpSocket!.on('error', (err: BusinessError) => {
      hilog.error(0x0000, 'Server', 'TCP错误: %{public}s', JSON.stringify(err));
      this.setConnectionStatus(TcpState.ERROR + ': ' + (err.message || '未知错误'));
      this.emit(ConnectionEvent.ERROR, err);
      this.stopHeartbeat();
      if (this.shouldReconnect) {
        this.scheduleReconnect();
      }
    });

    this.tcpSocket!.connect(connectOpts).then(() => {
      this.setConnectionStatus(TcpState.CONNECTED);
      this.reconnectAttempts = 0;
      this.startTcpListening();
      this.startHeartbeat();
    }).catch((connectErr: BusinessError) => {
      this.setConnectionStatus(TcpState.ERROR + ': ' + connectErr.message);
      this.emit(ConnectionEvent.ERROR, connectErr);
      if (this.shouldReconnect) {
        this.scheduleReconnect();
      }
    });
  }

  /** 断开 TCP 连接 */
  disconnect(): void {
    this.shouldReconnect = false;
    this.stopHeartbeat();
    this.cancelReconnect();

    try {
      if (this.tcpSocket) {
        this.tcpSocket.off('message');
        this.tcpSocket.off('error');
        this.tcpSocket.close();
      }
    } catch (_) { /* ignore */ }

    this.resetTcpSocket();
    this.setConnectionStatus(TcpState.DISCONNECTED);
  }

  /** 兼容旧接口 */
  disconnectDevice(): void {
    this.disconnect();
  }

  // ==================== 自动重连 ====================

  private scheduleReconnect(): void {
    if (!this.shouldReconnect) return;
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.setConnectionStatus(TcpState.ERROR + ': 重连次数已达上限');
      return;
    }

    this.reconnectAttempts++;
    // 指数退避: 1s, 2s, 4s, 8s, 16s
    const delay = this.baseReconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
    this.setConnectionStatus(TcpState.RECONNECTING + ` (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);

    this.cancelReconnect();
    this.reconnectTimer = setTimeout(() => {
      this.TCPServer();
    }, delay);
  }

  private cancelReconnect(): void {
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }

  /** 设置最大重连次数 */
  setMaxReconnectAttempts(max: number): void {
    this.maxReconnectAttempts = max;
  }

  // ==================== 数据收发 ====================

  /**
   * 发送数据到已连接的 TCP 设备
   * @param data 要发送的数据（可选，默认使用 inputText）
   * @returns Promise<boolean> 发送是否成功
   */
  async sendData(data?: string): Promise<boolean> {
    const sendContent = data || this.inputText;
    if (!sendContent) {
      this.sendResult = '无发送内容';
      return false;
    }

    if (this._connectionStatus !== TcpState.CONNECTED) {
      this.sendResult = '未连接，无法发送';
      return false;
    }

    try {
      const sendOpts: socket.TCPSendOptions = {
        data: sendContent,
      };
      await this.tcpSocket!.send(sendOpts);
      this.sendResult = '数据发送成功';
      this.inputText = '';
      return true;
    } catch (sendErr) {
      const msg = sendErr instanceof Error ? sendErr.message : JSON.stringify(sendErr);
      this.sendResult = '发送失败: ' + msg;
      return false;
    }
  }

  // ==================== 数据接收 ====================

  private startTcpListening(): void {
    if (!this.tcpSocket) return;

    this.tcpSocket.on('message', (value: socket.SocketMessageInfo) => {
      try {
        const textDecoder = util.TextDecoder.create('utf-8');
        const decodedMessage = textDecoder.decodeToString(new Uint8Array(value.message));

        this.mass = decodedMessage;
        this.sendResult = '收到: ' + decodedMessage;

        // 解析为结构化数据
        const deviceData = this.parseDeviceData(decodedMessage);
        this.emit(ConnectionEvent.DATA_RECEIVED, decodedMessage, deviceData);

        // 心跳响应检测
        if (decodedMessage.includes('pong') || decodedMessage.includes('PONG')) {
          this.lastHeartbeatResponse = Date.now();
        }
      } catch (e) {
        hilog.error(0x0000, 'Server', '数据解析错误: %{public}s', JSON.stringify(e));
      }
    });
  }

  // ==================== 心跳保活 ====================

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.lastHeartbeatResponse = Date.now();

    this.heartbeatTimer = setInterval(() => {
      // 检查心跳超时 (60s 无响应则触发重连)
      const elapsed = Date.now() - this.lastHeartbeatResponse;
      if (elapsed > this.heartbeatInterval * 2) {
        hilog.warn(0x0000, 'Server', '心跳超时，准备重连');
        this.setConnectionStatus(TcpState.RECONNECTING + ' (心跳超时)');
        this.stopHeartbeat();
        if (this.shouldReconnect) {
          this.scheduleReconnect();
        }
        return;
      }

      // 发送心跳 ping
      try {
        const pingOpts: socket.TCPSendOptions = { data: 'ping' };
        this.tcpSocket?.send(pingOpts);
      } catch (_) { /* ignore */ }
    }, this.heartbeatInterval);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== -1) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  // ==================== UDP 设备发现 ====================

  /** 启动 UDP 设备发现监听 */
  startUdpDiscovery(): boolean {
    if (this.isUdpListening) {
      hilog.info(0x0000, 'Server', 'UDP 已在监听中');
      return true;
    }

    try {
      this.resetUdpSocket();

      const bindAddr: socket.NetAddress = {
        address: '0.0.0.0',
        port: this.udpPort,
      };

      this.udpSocket!.bind(bindAddr, (err) => {
        if (err) {
          hilog.error(0x0000, 'Server', 'UDP 绑定失败: %{public}s', err.message);
          return;
        }
        hilog.info(0x0000, 'Server', 'UDP 监听端口: %{public}d', this.udpPort);
        this.isUdpListening = true;
        this.startUdpListening();
      });
      return true;
    } catch (error) {
      hilog.error(0x0000, 'Server', 'UDP 启动失败: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  /** 停止 UDP 监听 */
  stopUdpDiscovery(): void {
    try {
      if (this.udpSocket) {
        this.udpSocket.off('message');
        this.udpSocket.close();
      }
    } catch (_) { /* ignore */ }
    this.isUdpListening = false;
    this.resetUdpSocket();
    hilog.info(0x0000, 'Server', 'UDP 监听已停止');
  }

  private startUdpListening(): void {
    this.udpSocket?.on('message', (value: socket.SocketMessageInfo) => {
      try {
        const textDecoder = util.TextDecoder.create('utf-8');
        const message = textDecoder.decodeToString(new Uint8Array(value.message));

        const deviceData = this.parseDeviceData(message);
        deviceData.timestamp = Date.now();

        hilog.info(0x0000, 'Server', 'UDP 发现设备: %{public}s', deviceData.deviceName);
        this.emit(ConnectionEvent.DEVICE_FOUND, deviceData);
      } catch (error) {
        hilog.error(0x0000, 'Server', 'UDP 数据解析失败: %{public}s', JSON.stringify(error));
      }
    });
  }

  /** 发送 UDP 广播（触发设备响应） */
  sendUdpBroadcast(
    message: string,
    broadcastAddress: string = '255.255.255.255',
    port: number = 5000,
  ): boolean {
    try {
      const targetAddr: socket.NetAddress = {
        address: broadcastAddress,
        port: port,
      };

      this.udpSocket?.send({ data: message, address: targetAddr }, (err) => {
        if (err) {
          hilog.error(0x0000, 'Server', 'UDP 广播发送失败: %{public}s', err.message);
        } else {
          hilog.info(0x0000, 'Server', 'UDP 广播已发送: %{public}s', message);
        }
      });
      return true;
    } catch (error) {
      hilog.error(0x0000, 'Server', 'UDP 广播异常: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  // ==================== 数据解析 ====================

  /**
   * 解析设备数据: "设备名,数据1,数据2,..."
   * 示例: "ESP32_Sensor,25.5,60,1024,1,0"
   */
  parseDeviceData(rawString: string): IoTDeviceData {
    const trimmed = rawString.trim();
    const parts = trimmed.split(',');
    const deviceName = parts[0] || '未知设备';

    const data: string[] = [];
    for (let i = 1; i < parts.length && i <= 6; i++) {
      data.push(parts[i].trim());
    }

    return {
      deviceName,
      data,
      rawString,
      timestamp: Date.now(),
    };
  }

  /** 获取设备数据字段 */
  getDeviceData(deviceData: IoTDeviceData, index: number): string | null {
    if (index >= 0 && index < deviceData.data.length) {
      return deviceData.data[index];
    }
    return null;
  }

  /** 字符串转数字 */
  parseNumber(value: string): number | null {
    const num = Number(value);
    return isNaN(num) ? null : num;
  }

  /** 检查设备数据是否有效 */
  isValidDeviceData(deviceData: IoTDeviceData): boolean {
    return deviceData.deviceName !== '未知设备' && deviceData.data.length > 0;
  }

  /** 清理所有资源 */
  destroy(): void {
    this.disconnect();
    this.stopUdpDiscovery();
    this.eventListeners.clear();
  }
}

// 导出单例
export const server = new Server();
