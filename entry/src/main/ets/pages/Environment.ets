// Environment.ets
import {Server} from '../tools/server'


@Entry
@Component
export default struct Environment {
  @State indoorTemp: number = 0 // 室内温度
  @State indoorHumidity: number = 0 // 室内湿度
  @State outdoorTemp: number = 0 // 室外温度
  @State outdoorHumidity: number = 0 // 室外湿度

  @State rece : string = '未连接'
  @State TCP: Server = new Server()

  // 模拟实时数据更新
  // aboutToAppear() {
  //   setInterval(() => {
  //     // 模拟数据变化
  //     this.indoorTemp = this.getRandomChange(this.indoorTemp, 0.5);
  //     this.indoorHumidity = this.getRandomChange(this.indoorHumidity, 2);
  //     this.outdoorTemp = this.getRandomChange(this.outdoorTemp, 1);
  //     this.outdoorHumidity = this.getRandomChange(this.outdoorHumidity, 3);
  //   }, 3000); // 每3秒更新一次
  // }
  //
  // // 辅助方法：生成随机变化
  // private getRandomChange(baseValue: number, range: number): number {
  //   const change = (Math.random() * range * 2) - range; // -range到+range之间的随机数
  //   const newValue = baseValue + change;
  //   return parseFloat(newValue.toFixed(1)); // 保留一位小数
  // }



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
        Text('环境监测')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
      }
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Start)

      // 温湿度卡片 - 居中占25%
      Column() {
        // 温度显示
        Row() {
          Image($r('app.media.ic_temperature'))
            .width(30)
            .height(30)
            .margin({ right: 8 })
          Column() {
            Text('实时温度')
              .fontSize(14)
              .fontColor($r('app.color.jet_black'))
            Text(`${this.indoorTemp}°C`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.dark_green'))
          }
        }
        .margin({ bottom: 12 })

        // 湿度显示
        Row() {
          Image($r('app.media.ic_humidity'))
            .width(30)
            .height(30)
            .margin({ right: 8 })
          Column() {
            Text('实时湿度')
              .fontSize(14)
              .fontColor($r('app.color.jet_black'))
            Text(`${this.indoorHumidity}%`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.dark_green'))
          }
        }
      }
      .width('90%')
      .height('25%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ top: 20 })

      // 环境数据列表
      List() {
        // 室内环境
        ListItem() {
          Column() {
            Text('室内环境')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ bottom: 8 })

            // 室内温度
            Row() {
              Text('温度:')
                .fontSize(16)
                .fontColor(Color.White)
                .margin({ right: 8 })
              Text(`${this.indoorTemp}°C`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .margin({ bottom: 4 })

            // 室内湿度
            Row() {
              Text('湿度:')
                .fontSize(16)
                .fontColor(Color.White)
                .margin({ right: 8 })
              Text(`${this.indoorHumidity}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.dark_green')) // 深一点的绿色
          .borderRadius(12)
        }
        .margin({ bottom: 12 })

        // 室外环境
        ListItem() {
          Column() {
            Text('室外环境')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ bottom: 8 })

            // 室外温度
            Row() {
              Text('温度:')
                .fontSize(16)
                .fontColor(Color.White)
                .margin({ right: 8 })
              Text(`${this.outdoorTemp}°C`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .margin({ bottom: 4 })

            // 室外湿度
            Row() {
              Text('湿度:')
                .fontSize(16)
                .fontColor(Color.White)
                .margin({ right: 8 })
              Text(`${this.outdoorHumidity}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }

            // 可以添加更多室外环境数据，如空气质量等
            Row() {
              Text('空气质量:')
                .fontSize(16)
                .fontColor(Color.White)
                .margin({ right: 8 })
              Text('良好')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Green)
            }
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.dark_green')) // 深一点的绿色
          .borderRadius(12)
        }
      }
      .width('90%')
      .layoutWeight(1)
      .margin({ top: 12, bottom: 20 })

      Text("天气：" + this.rece)
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
    }

    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.olive_green')) // 浅绿色背景
    .alignItems(HorizontalAlign.Center)
  }
}