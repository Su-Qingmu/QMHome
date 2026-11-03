@Entry
@Component
export default struct MineContent {
  @Builder
  item(msg: string) {
    Row() {
      Text(msg)
        .fontSize(20)
        .fontWeight(500)
        .layoutWeight(1)

      Image($r('app.media.ic_right'))
        .objectFit(ImageFit.Contain)
        .height(12)
        .width(7)
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .margin({ top: 15, bottom: 15 })
  }

  build() {
    Column() {
      // 顶部用户信息区域
      Row() {
        Column() {
          Image($r('app.media.ic_user'))
            .height(66)
            .width(66)
            .objectFit(ImageFit.Contain)
            .margin({ top: 71 })

          Text('小猫')
            .fontSize(20)
            .margin({ bottom: 6 })
        }
        .width('100%')
      }
      .width('100%')
      .height('25%')
      .backgroundColor($r('app.color.silver_grey'))

      // 功能列表区域
      Column() {
        this.item('个人资料')
        Divider()
        this.item('语音控制')
        Divider()
        this.item('中枢与网关')
        Divider()
        this.item('密保问题')
        Divider()
        this.item('设备管理')
        Divider()
        this.item('应用授权')
        Divider()
        this.item('检测更新')
        Divider()
        this.item('关于')
        Divider()
      }
      .width('100%')
      .flexGrow(1) // 使用剩余空间
    }
    .width('100%')
    .height('100%')
  }
}