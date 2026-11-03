// import {Server} from '../tools/server'
//
// @Entry
// @Component
// struct Light {
//   @State rece : string = '未连接'
//
//   @State TCP: Server = new Server()
//
//   build() {
//     Column() {
//       Text('连接状态:')
//         .fontSize(16)
//         .margin({ top: 10 });
//       Text(this.TCP.connectionStatus)
//         .fontSize(14)
//         .margin({ top: 5 });
//
//       Text(this.rece)
//
//       TextInput({ placeholder: '在这里输入 IP 地址' })
//         .width('90%')
//         .height(40)
//         .margin({ top: 10 })
//         .onChange((value: string) => {
//           this.TCP.tcpAddress = value;
//         });
//       Text('请输入目标端口号:')
//         .fontSize(16)
//         .margin({ top: 10 });
//       TextInput({ placeholder: '在这里输入端口号' })
//         .width('90%')
//         .height(40)
//         .margin({ top: 10 })
//         .onChange((value: string) => {
//           const port = parseInt(value, 10);
//           if (!isNaN(port)) {
//             this.TCP.tcpPort = port;
//           } else {
//             console.error('输入的端口号无效');
//           }
//         });
//
//       Button('发送')
//         .width('40%')
//         .height(40)
//         .margin({ top: 10 })
//         .onClick(async () => { // 将回调函数改为 async 函数
//           this.TCP.TCPServer();
//           let intervalId = setInterval(async () => {
//             if (this.TCP.connectionStatus === '连接到目标设备成功') {
//               this.TCP.inputText = "中文";
//               this.TCP.sendData();
//               console.log("发送");
//               this.TCP.receData();
//               this.rece = this.TCP.mass;
//             } else {
//               clearInterval(intervalId); // 当连接状态改变时，清除定时器
//             }
//           }, 5000);
//         });
//
//     }
//   }
// }