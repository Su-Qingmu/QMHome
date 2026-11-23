import { Server } from  '../tools/server'


@Entry
@Component
export default struct Monitors {
  @State cameraImage: Resource = $r('app.media.ic_lock_closed') // 默认摄像头图片
  // @State lockRecords: Array<LockRecord> = [
  //   { method: 'NFC', result: '成功', time: '2023-05-15 10:30:22' },
  //   { method: '人脸识别', result: '失败', time: '2023-05-15 10:28:15' },
  //   { method: 'APP远程', result: '成功', time: '2023-05-15 09:45:33' },
  //   { method: 'NFC', result: '成功', time: '2023-05-15 09:30:12' },
  //   { method: '人脸识别', result: '成功', time: '2023-05-15 08:15:42' }
  // ]

  @State rece : string = '未连接'
  @State TCP: Server = new Server()

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ right: 12 })
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })
        Text('门锁监控')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
      }
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Start)
      // 顶部摄像头画面 (占20%高度)


      Stack() {
        Image(this.cameraImage)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        // 可以添加摄像头状态信息
        Text('实时监控中...')
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#66000000')
          .padding(5)
          .borderRadius(10)
          .margin(10)
          .align(Alignment.TopStart)
      }
      .height('20%')
      .width('100%')
      .margin({ bottom: 10 })


      // 开锁记录表格
      // List({ space: 10 }) {
      //   ForEach(this.lockRecords, (item: LockRecord) => {
      //     ListItem() {
      //       Row() {
      //         // 开锁方式列
      //         Text(item.method)
      //           .width('30%')
      //           .textAlign(TextAlign.Start)
      //           .fontSize(14)
      //
      //         // 开锁结果列
      //         Text(item.result)
      //           .width('30%')
      //           .textAlign(TextAlign.Center)
      //           .fontSize(14)
      //           .fontColor(item.result === '成功' ? '#00FF00' : '#FF0000')
      //
      //         // 开锁时间列
      //         Text(item.time)
      //           .width('40%')
      //           .textAlign(TextAlign.End)
      //           .fontSize(12)
      //       }
      //       .width('100%')
      //       .padding(10)
      //       .backgroundColor('#F5F5F5')
      //       .borderRadius(8)
      //     }
      //   });
      // }
      // .width('100%')
      // .height('80%')
      // .divider({ strokeWidth: 1, color: '#EEE' })
      // .scrollBar(BarState.Off)



        Text("检测到：" + this.TCP.connectionStatus)
          .fontSize(16)
          .fontColor(Color.Black)
          .margin({ right: 8 })

        TextInput({ placeholder: '在这里输入 IP 地址' })
          .width('90%')
          .height(40)
          .margin({ top: 10 })
          .onChange((value: string) => {
            this.TCP.tcpAddress = value;
          });
        Text('请输入目标端口号:')
          .fontSize(16)
          .margin({ top: 10 });
        TextInput({ placeholder: '在这里输入端口号' })
          .width('90%')
          .height(40)
          .margin({ top: 10 })
          .onChange((value: string) => {
            const port = parseInt(value, 10);
            if (!isNaN(port)) {
              this.TCP.tcpPort = port;
            } else {
              console.error('输入的端口号无效');
            }
          });
        Button('连接')
          .width('40%')
          .height(40)
          .margin({ top: 10 })
          .onClick(async () => { // 将回调函数改为 async 函数
            this.TCP.TCPServer();
            let intervalId = setInterval(async () => {
              if (this.TCP.connectionStatus === '连接到目标设备成功') {
                this.TCP.inputText = "1";
                this.TCP.sendData();
                console.log("发送");
                this.rece = this.TCP.mass;
              } else {
                clearInterval(intervalId); // 当连接状态改变时，清除定时器
              }
            }, 5000);
          });

        Text('\n'+this.rece)
          .fontSize(22)
          .fontColor(Color.Black)
          .margin({ right: 8 })

    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor($r('app.color.olive_green'))
  }
}

interface LockRecord {
  method: string;
  result: string;
  time: string;
}