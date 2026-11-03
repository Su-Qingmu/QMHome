/**
 * ⚠️ 旧版 v1 TCP/UDP 通信 — 已由 server.ets 替代
 *
 * 保留作为参考，存在以下问题：
 * - 使用 String.fromCharCode() 而非 TextDecoder（鸿蒙6旧API）
 * - 模块级 socket 实例（单例反模式）
 * - 缺少统一的错误处理
 */
import { socket } from '@ohos.net.socket';
import { BusinessError } from '@kit.BasicServicesKit';

const tcp: socket.TCPSocket = socket.constructTCPSocketInstance();
const udp: socket.UDPSocket = socket.constructUDPSocketInstance();

let tcpAddress: string = '192.168.1.100';
let tcpPort: number = 80;
let inputText: string = '';
let sendResult: string = '';
let mass: string = '';

function TCPServer(address?: string, port?: number): void {
  if (address) tcpAddress = address;
  if (port) tcpPort = port;

  const targetAddr: socket.NetAddress = {
    address: tcpAddress,
    port: tcpPort,
  };

  const connectOpts: socket.TCPConnectOptions = {
    address: targetAddr,
    timeout: 5000,
  };

  tcp.on('message', (value: socket.SocketMessageInfo) => {
    try {
      const uint8Array = new Uint8Array(value.message);
      let message = '';
      for (let i = 0; i < uint8Array.length; i++) {
        message += String.fromCharCode(uint8Array[i]);
      }
      mass = message;
      sendResult = '收到: ' + message;
    } catch (e) {
      console.error('数据解析失败');
    }
  });

  tcp.on('error', (err: BusinessError) => {
    console.error('TCP错误: ' + err.message);
  });

  tcp.connect(connectOpts).then(() => {
    console.log('连接成功');
  }).catch((err: BusinessError) => {
    console.error('连接失败: ' + err.message);
  });
}

function sendData(data?: string): void {
  const sendContent = data || inputText;
  if (!sendContent) return;

  const sendOpts: socket.TCPSendOptions = {
    data: sendContent,
  };

  tcp.send(sendOpts).then(() => {
    sendResult = '发送成功';
    inputText = '';
  }).catch((err: BusinessError) => {
    sendResult = '发送失败: ' + err.message;
  });
}
