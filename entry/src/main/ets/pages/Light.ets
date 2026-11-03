// Light.ets
import router from '@ohos.router';
import {Server} from '../tools/server'


@Entry
@Component
struct Light {
  @State bright: number = 0 // 内部使用的亮度值
  @State lastBright: number = 80 // 存储最后一次修改的亮度值，首次打开默认 80
  @State temperature: number = 50 // 色温值 0-100 (冷到暖)
  @State isOn: boolean = false // 开关状态
  @State TCP: Server = new Server()

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_back')) // 返回图标
          .width(24)
          .height(24)
          .onClick(() => {
            router.back()
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

      Text('连接状态:')
        .fontSize(16)
        .margin({ top: 10 });
      Text(this.TCP.connectionStatus)
        .fontSize(14)
        .margin({ top: 5 });

      // 开关按钮
      Row() {
        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .onChange((isOn: boolean) => {
            this.isOn = isOn
            console.log('当前开关状态: ', this.isOn)
            if (isOn) {
              this.bright = this.lastBright;
            } else {
              this.lastBright = this.bright;
              this.bright = 0;
            }
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
              this.temperature = value
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.olive_green')) // 浅绿色背景
  }
}