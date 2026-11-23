// Smokealarm.ets
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SmokePrivacy } from './components/SmokePrivacy';
import { Server } from  '../tools/server'

@Entry
@Component
export default struct Smokealarm {
  @State showSmokeAlert: boolean = false; // 控制弹窗显示
  @State rece : string = '未连接'
  @State TCP: Server = new Server()

  build() {
    Stack() { // 使用Stack叠加弹窗
      Column() {
        // 顶部返回按钮和标题
        Row() {
          Image($r('app.media.ic_back')) // 返回图标
            .width(24)
            .height(24)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })

          Text('烟雾报警传感器')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 40 }) // 平衡返回按钮的宽度
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .backgroundColor(Color.White)

        // 主要内容区域
        Column() {
          // 传感器图片
          Image($r('app.media.ic_somkebell')) // 传感器图标
            .width(120)
            .height(120)
            .margin({ top: 40, bottom: 20 })

          // 添加一个测试按钮（实际应由传感器触发）
          Button('模拟烟雾报警')
            .width(200)
            .height(50)
            .fontSize(18)
            .onClick(() => {
              this.showSmokeAlert = true;
            })
            .margin({ top: 30 })

          Text("检测到：" + this.rece)
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
                  if(this.TCP.mass == '超标'){
                    this.showSmokeAlert = true;
                  }
                } else {
                  clearInterval(intervalId); // 当连接状态改变时，清除定时器
                }
              }, 5000);
            });

        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 弹窗组件（条件渲染）
        if (this.showSmokeAlert) {
          SmokePrivacy({ showAlert: this.showSmokeAlert })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.olive_green')) // 浅绿色背景
  }
}