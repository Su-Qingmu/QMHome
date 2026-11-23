// Light.ets — 灯光控制（原 test2 功能合并，含 Socket 发送与频率控制）
import { Server } from '../tools/server';

@Entry
@Component
struct Light {
  @State bright: number = 0; // 内部使用的亮度值
  @State lastBright: number = 80; // 存储最后一次修改的亮度值，首次打开默认 80
  @State temperature: number = 50; // 色温值 0-100 (冷到暖)
  @State isOn: boolean = false; // 开关状态
  @State TCP: Server = new Server();
  private lastSendTime: number = 0; // 记录上次发送数据的时间
  private sendInterval: number = 200; // 发送间隔，200ms 即每秒 5 次

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_back')) // 返回图标
          .width(24)
          .height(24)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Text('灯光控制')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Image($r('app.media.ic_more')) // 更多设置图标
          .width(24)
          .height(24)
      }
      .width('100%')
      .padding(16)

      Text('Socket 连接状态:')
        .fontSize(16)
        .margin({ top: 10 });
      Text(this.TCP.connectionStatus)
        .fontSize(14)
        .margin({ top: 5 });

      // 开关按钮
      Row() {
        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .onChange((isOn: boolean) => {
            this.isOn = isOn;
            console.log('当前开关状态: ', this.isOn);
            if (isOn) {
              this.bright = this.lastBright;
            } else {
              this.lastBright = this.bright;
              this.bright = 0;
            }
            // 开关状态改变时发送亮度值
            this.sendBrightnessValueOverSocket(this.bright);
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 30 })

      // 亮度调节
      Column() {
        Row() {
          Image($r('app.media.ic_brightness_low'))
            .width(20)
            .height(20)
            .margin({ right: 1 })

          Slider({
            value: this.bright,
            min: 0,
            max: 100,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockColor($r('app.color.forest_green'))
            .trackColor($r('app.color.light_green'))
            .selectedColor($r('app.color.forest_green'))
            .onChange((value: number) => {
              this.bright = value;
              this.lastBright = value;
              // 控制发送频率
              const currentTime = Date.now();
              if (currentTime - this.lastSendTime >= this.sendInterval) {
                this.sendBrightnessValueOverSocket(value);
                this.lastSendTime = currentTime;
              }
            })

          Image($r('app.media.ic_brightness_high'))
            .width(20)
            .height(20)
            .margin({ left: 1 })
        }
        .width('75%')
        .alignItems(VerticalAlign.Center)

        Text('亮度: ' + this.bright + '%')
          .fontSize(14)
          .fontColor($r('app.color.jet_black'))
          .margin({ top: 8 })
      }
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 16 })
      .width('90%')

      // 色温调节
      Column() {
        Row() {
          Image($r('app.media.ic_temp_cold'))
            .width(20)
            .height(20)
            .margin({ right: 1 })

          Slider({
            value: this.temperature,
            min: 0,
            max: 100,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockColor($r('app.color.forest_green'))
            .trackColor($r('app.color.light_green'))
            .selectedColor($r('app.color.forest_green'))
            .onChange((value: number) => {
              this.temperature = value;
            })

          Image($r('app.media.ic_temp_warm'))
            .width(20)
            .height(20)
            .margin({ left: 1 })
        }
        .width('75%')
        .alignItems(VerticalAlign.Center)

        Text('色温: ' + (this.temperature > 50 ? '暖' : '冷'))
          .fontSize(14)
          .fontColor($r('app.color.jet_black'))
          .margin({ top: 8 })
      }
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .width('90%')

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
      Text('请输入要发送的信息:')
        .fontSize(16)
        .margin({ top: 10 });
      TextInput({ placeholder: '在这里输入信息' })
        .width('90%')
        .height(40)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.TCP.inputText = value;
        });
      Button('发送')
        .width('40%')
        .height(40)
        .margin({ top: 10 })
        .onClick(() => {
          this.TCP.sendData();
        });
      Text(this.TCP.sendResult)
        .fontSize(14)
        .margin({ top: 10 });
      Button('重连')
        .width('40%')
        .height(40)
        .margin({ top: 10 })
        .onClick(() => {
          this.TCP.TCPServer();
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.olive_green')) // 浅绿色背景
  }

  // 发送亮度值的 Socket 信息
  sendBrightnessValueOverSocket(value: number) {
    // 确保已经连接到服务器
    if (this.TCP.connectionStatus === '连接到目标设备成功') {
      // 确保发送的值在 0 - 100 范围内
      const validValue = Math.min(100, Math.max(0, value));
      // 设置要发送的数据，这里将亮度值转换为字符串发送
      this.TCP.inputText = validValue.toString();
      // 调用 Server 类的 sendData 方法发送数据
      this.TCP.sendData();
    } else {
      console.log('尚未连接到服务器，无法发送数据');
    }
  }
}
