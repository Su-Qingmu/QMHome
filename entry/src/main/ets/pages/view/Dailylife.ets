// view/Dailylife.ets
@Entry
@Component
export default struct Dailylife {
  aboutToAppear() {
    // 可以在这里添加组件显示前的初始化逻辑
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('探索 我的智能')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()

        // 使用ic_more图片作为按钮
        Image($r('app.media.ic_more'))
          .width(25)
          .height(25)
          .margin({ right: 16 })
          .onClick(() => {
            // 添加新设备或功能的逻辑
          })

      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 主内容区域
      Scroll() {
        Column() {
          // 第一行 - 两个模块
          Row() {
            // 离家回家模块
            Column() {
              Row() {
                Image($r('app.media.ic_light_on')) // 开门图标
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })

                Column() {
                  Text('离家')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('回家')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('大量用户都在使用')
                    .fontSize(12)
                    .opacity(0.7)
                }
                .layoutWeight(1)


              }
              .padding(10)
              Row() {
                Blank()
                Image($r('app.media.ic_arrow_right'))
                  //Image($r('app.media.ic_projector'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('48%')
            .height('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .onClick(() => {
              // 点击整个模块跳转
            })

            Blank().width('4%')

            // 灯全关人来灯亮模块
            Column() {
              Row() {
                Image($r("app.media.ic_indoors")) // 关门图标
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })

                Column() {
                  Text('灯全关')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('人来灯亮')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('大量用户都在使用')
                    .fontSize(12)
                    .opacity(0.7)
                }
                .layoutWeight(1)


              }
              .padding(10)
              Row() {
                Blank()
                Image($r('app.media.ic_arrow_right'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('48%')
            .height('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)

          }
          .width('100%')
          .height('25%')
          .margin({ bottom: 16 })

          // 第二行 - 两个模块
          Row() {
            // 影音娱乐模块
            Column() {
              Row() {
                Image($r('app.media.ic_projector')) // 新增投影仪图标
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })

                Column() {
                  Text('氛围')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('70万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                    .margin({ bottom: 10 })

                  Text('观影')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('53万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                }
                .layoutWeight(1)
              }
              .padding(10)

              Row() {
                Blank()
                Image($r('app.media.ic_arrow_right'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('48%')
            .height('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .onClick(() => {
              // 跳转到影音娱乐页面
            })

            Blank().width('4%')

            // 舒适环境模块
            Column() {
              Row() {
                Image($r('app.media.ic_leaf')) // 新增叶子图标
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })

                Column() {
                  Text('结束运动')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('58万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                    .margin({ bottom: 10 })

                  Text('空气净化')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('53万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                }
                .layoutWeight(1)
              }
              .padding(10)

              Row() {
                Blank()
                Image($r('app.media.ic_arrow_right'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('48%')
            .height('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .onClick(() => {
              // 跳转到舒适环境页面
            })
          }
          .width('100%')
          .height('25%')
          .margin({ bottom: 16 })

          // 第三行 - 两个模块
          Row() {
            // 最新应用模块
            Column() {
              Row() {
                Image($r('app.media.ic_somkebell')) // 新增门铃图标
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })

                Column() {
                  Text('洗衣完成时，降低晾衣架')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('1万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                    .margin({ bottom: 10 })

                  Text('不错过门铃')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('1万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                }
                .layoutWeight(1)
              }
              .padding(10)

              Row() {
                Blank()
                Image($r('app.media.ic_arrow_right'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('48%')
            .height('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .onClick(() => {
              // 跳转到最新应用页面
            })

            Blank().width('4%')

            // 安全看家模块
            Column() {
              Row() {
                Image($r('app.media.ic_humidity')) // 新增安全图标
                  .width(40)
                  .height(40)
                  .margin({ right: 10 })

                Column() {
                  Text('漏水提醒')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('27万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                    .margin({ bottom: 10 })

                  Text('门窗打开提醒')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text('21万人已使用')
                    .fontSize(12)
                    .opacity(0.7)
                }
                .layoutWeight(1)
              }
              .padding(10)

              Row() {
                Blank()
                Image($r('app.media.ic_arrow_right'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
            }
            .width('48%')
            .height('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .onClick(() => {
              // 跳转到安全看家页面
            })
          }
          .width('100%')
          .height('25%')
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.olive_green'))
  }
}