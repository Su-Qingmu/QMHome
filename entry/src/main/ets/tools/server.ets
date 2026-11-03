/**
 * IoT设备通信服务层——提供TCP/IP数据收发及UDP设备发现功能
 *
 * 使用说明：
 *   启动：TCPServer("192.168.1.xx", 80) 或 使用 inputText/mass/sendResult 绑定UI
 *
 * 数据格式约定：
 *   设备数据采用逗号分隔的字符串格式，例如： "设备名,数据1,数据2,..."
 *
 *   示例数据字段含义（灯光设备）：
 *     [0] 设备名称
 *     [1] 当前电压(V)，如 25.5
 *     [2] 当前电流(A)，如 0.60
 *     [3] 当前功率(W)，如 1024
 *     [4] 继电器状态， 如 1 (开)、0(关)
 *     [5] 保留位，如 0
 *     [6] 保留位，如 0
 *
 *   示例： "ESP32_Sensor,25.5,60,1024,1,0"
 */
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 定义设备数据结构
export interface IoTDeviceData {
  deviceName: string;
  data: string[];
  rawString: string;
  timestamp: number;
}

export class Server {
  tcpSocket: socket.TCPSocket | null = null;
  UdpSocket: socket.UDPSocket | null = null;
  tcpAddress: string = '';
  tcpPort: number = 80;
  inputText: string = '';
  sendResult: string = '';
  mass: string = '';
  private isUdpListening: boolean = false;

  // TCP连接管理
  TCPServer(address?: string, port?: number): void {
    if (address) this.tcpAddress = address;
    if (port) this.tcpPort = port;

    if (!this.tcpAddress || !this.tcpPort) {
      console.log('请输入IP和端口');
      return;
    }

    try {
      if (this.tcpSocket) {
        try {
          this.tcpSocket.off('message');
          this.tcpSocket.off('error');
          this.tcpSocket.close();
        } catch (_) { /* ignore */ }
      }
    } catch (_) { /* ignore */ }

    this.tcpSocket = socket.constructTCPSocketInstance();

    const targetAddr: socket.NetAddress = {
      address: this.tcpAddress,
      port: this.tcpPort,
    };

    const connectOpts: socket.TCPConnectOptions = {
      address: targetAddr,
      timeout: 5000,
    };

    this.tcpSocket.on('message', (value: socket.SocketMessageInfo) => {
      try {
        const textDecoder = util.TextDecoder.create('utf-8');
        const decodedMessage = textDecoder.decodeToString(new Uint8Array(value.message));
        this.mass = decodedMessage;
        this.sendResult = '收到: ' + decodedMessage;
      } catch (e) {
        console.log('数据解析错误: ' + JSON.stringify(e));
      }
    });

    this.tcpSocket.on('error', (err: BusinessError) => {
      console.log('连接错误: ' + JSON.stringify(err));
      this.sendResult = '连接异常: ' + err.message;
    });

    this.tcpSocket.connect(connectOpts).then(() => {
      console.log('TCP连接成功');
      this.sendResult = '连接成功';
    }).catch((connectErr: BusinessError) => {
      console.log('连接失败: ' + connectErr.message);
      this.sendResult = '连接失败: ' + connectErr.message;
    });
  }

  sendData(data?: string): boolean {
    const sendContent = data || this.inputText;
    if (!sendContent) {
      this.sendResult = '无发送内容';
      return false;
    }

    if (!this.tcpSocket) {
      this.sendResult = '未连接';
      return false;
    }

    try {
      const sendOpts: socket.TCPSendOptions = {
        data: sendContent,
      };
      this.tcpSocket.send(sendOpts).then(() => {
        this.sendResult = '数据发送成功';
        this.inputText = '';
      }).catch((sendErr: BusinessError) => {
        this.sendResult = '发送失败: ' + sendErr.message;
      });
      return true;
    } catch (sendErr) {
      this.sendResult = '发送异常: ' + JSON.stringify(sendErr);
      return true;
    }
  }

  disconnectDevice(): void {
    try {
      if (this.tcpSocket) {
        this.tcpSocket.off('message');
        this.tcpSocket.off('error');
        this.tcpSocket.close();
      }
    } catch (_) { /* ignore */ }
    this.tcpSocket = socket.constructTCPSocketInstance();
    this.sendResult = '已断开连接';
  }

  // UDP设备发现
  startUdpDiscovery(): boolean {
    if (this.isUdpListening) {
      console.log('UDP已在监听中');
      return true;
    }

    try {
      if (this.UdpSocket) {
        try {
          this.UdpSocket.off('message');
          this.UdpSocket.close();
        } catch (_) { /* ignore */ }
      }
    } catch (_) { /* ignore */ }

    this.UdpSocket = socket.constructUDPSocketInstance();

    const bindAddr: socket.NetAddress = {
      address: '0.0.0.0',
      port: 5000,
    };

    this.UdpSocket.bind(bindAddr, (err) => {
      if (err) {
        console.log('UDP绑定失败: ' + err.message);
        return;
      }
      console.log('UDP监听端口: 5000');
      this.isUdpListening = true;
    });

    this.UdpSocket.on('message', (value: socket.SocketMessageInfo) => {
      try {
        const textDecoder = util.TextDecoder.create('utf-8');
        const message = textDecoder.decodeToString(new Uint8Array(value.message));
        console.log('UDP收到: ' + message);
      } catch (error) {
        console.log('UDP数据解析失败: ' + JSON.stringify(error));
      }
    });

    return true;
  }

  stopUdpDiscovery(): void {
    try {
      if (this.UdpSocket) {
        this.UdpSocket.off('message');
        this.UdpSocket.close();
      }
    } catch (_) { /* ignore */ }
    this.isUdpListening = false;
    this.UdpSocket = socket.constructUDPSocketInstance();
    console.log('UDP监听已停止');
  }

  // 数据解析
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

  getDeviceData(deviceData: IoTDeviceData, index: number): string | null {
    if (index >= 0 && index < deviceData.data.length) {
      return deviceData.data[index];
    }
    return null;
  }

  parseNumber(value: string): number | null {
    const num = Number(value);
    return isNaN(num) ? null : num;
  }

  isValidDeviceData(deviceData: IoTDeviceData): boolean {
    return deviceData.deviceName !== '未知设备' && deviceData.data.length > 0;
  }
}

export const server = new Server();
