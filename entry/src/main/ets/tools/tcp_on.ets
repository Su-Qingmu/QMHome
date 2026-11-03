/**
 * TCP消息监听测试—技术验证片段
 *
 * 功能：模块级注册TCP消息监听，用于技术可行性验证
 * 注意：仅用于验证，非正式功能代码
 */
import { socket } from '@ohos.net.socket';
import { BusinessError } from '@kit.BasicServicesKit';

const tcp: socket.TCPSocket = socket.constructTCPSocketInstance();

tcp.on('message', (value: socket.SocketMessageInfo) => {
  try {
    const uint8Array = new Uint8Array(value.message);
    let message = '';
    for (let i = 0; i < uint8Array.length; i++) {
      message += String.fromCharCode(uint8Array[i]);
    }
    console.log('TCP收到: ' + message);
  } catch (e) {
    console.error('解析失败');
  }
});

tcp.on('error', (err: BusinessError) => {
  console.error('TCP错误: ' + err.message);
});
