// SmokePrivacy.axkts
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

@Component
export struct SmokePrivacy {
  @Prop showAlert: boolean = false; // 由父组件控制显示

  build() {
    Column() {
      // 警告标题行
      Row() {
        Text('警告！')
          .fontSize(36)
          .fontColor(Color.Red)
          .fontWeight(FontWeight.Bold)
          .margin({ right: 10 })

        Image($r('app.media.lock_open_fill'))
          .width(40)
          .height(40)
      }
      .justifyContent(FlexAlign.Center)
      .margin({ top: 30, bottom: 20 })

      // 警告内容
      Text('检测到烟雾浓度过高！')
        .fontSize(18)
        .fontColor(Color.Black)
        .margin({ bottom: 10 })

      Text('当前浓度: 危险级别')
        .fontSize(16)
        .fontColor(Color.Black)
        .margin({ bottom: 10 })

      Text('建议立即通风并检查火源')
        .fontSize(16)
        .fontColor(Color.Black)
        .margin({ bottom: 30 })

      // 确认按钮
      Button('我知道了')
        .width(200)
        .height(45)
        .backgroundColor(Color.Red)
        .onClick(() => {
          this.showAlert = true;
          // 这里可以添加其他处理逻辑
        })
    }
    .width('80%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 20, color: Color.Red, offsetX: 0, offsetY: 0 })
    .position({ x: '10%', y: '20%' }) // 居中偏上位置
  }
}