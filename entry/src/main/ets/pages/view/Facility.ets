// Facility.ets
import { router } from '@kit.ArkUI';  // 导入ArkUI的路由功能
import { BusinessError } from '@kit.BasicServicesKit';  // 导入基础服务错误类型
import { hilog } from '@kit.PerformanceAnalysisKit';  // 导入性能分析日志功能

@Entry  // 标记这个组件为应用的入口组件
@Component  // 标记这个结构体是一个自定义组件
export default struct Facility {  // 定义一个名为Facility的组件

  // 定义一个设备项的Builder方法，用于创建可复用的设备项UI
  @Builder
  deviceItem(icon: Resource, title: string, subtitle: string, hasArrow: boolean = true) {
    Row() {  // 创建一个行布局
      Row() {  // 嵌套的行布局，用于图标和文本
        Image(icon)  // 显示设备图标
          .width(24)  // 设置图标宽度
          .height(24)  // 设置图标高度
          .margin({ right: 12 })  // 设置右边距
        Column() {  // 创建一个列布局，用于标题和副标题
          Text(title)  // 显示设备标题
            .fontSize(16)  // 设置字体大小
            .fontColor($r('app.color.jet_black'))  // 设置字体颜色
          Text(subtitle)  // 显示设备副标题
            .fontSize(12)  // 设置字体大小
            .fontColor($r('app.color.silver_grey'))  // 设置字体颜色
        }
        .alignItems(HorizontalAlign.Start)  // 设置列内子项左对齐
      }
      .layoutWeight(1)  // 设置布局权重为1，使其占据剩余空间

      if (hasArrow) {  // 如果有箭头标志
        Image($r('app.media.ic_right'))  // 显示右箭头图标
          .width(12)  // 设置图标宽度
          .height(12)  // 设置图标高度
      }
    }
    .width('100%')  // 设置行宽度为100%
    .padding(16)  // 设置内边距
    .backgroundColor(Color.White)  // 设置背景色为白色
    .borderRadius(12)  // 设置圆角
    .margin({ bottom: 12 })  // 设置下边距
    .justifyContent(FlexAlign.SpaceBetween)  // 设置子项两端对齐
  }

  // 组件的build方法，定义UI结构
  build() {
    Column() {  // 创建一个列布局作为主容器
      // 顶部标题和天气
      Row() {  // 创建一个行布局
        Text('全屋')  // 显示"全屋"文本
          .fontSize(18)  // 设置字体大小
          .fontWeight(FontWeight.Bold)  // 设置字体粗细
          .margin({ right: 16 })  // 设置右边距
        Text('卧室')  // 显示"卧室"文本
          .fontSize(18)  // 设置字体大小
          .margin({ right: 16 })  // 设置右边距
        Text('客厅')  // 显示"客厅"文本
          .fontSize(18)  // 设置字体大小

        Row() {  // 创建一个行布局用于天气信息
          Image($r('app.media.ic_cloudy'))  // 显示天气图标
            .width(16)  // 设置图标宽度
            .height(16)  // 设置图标高度
            .margin({ right: 4 })  // 设置右边距
          Text('苏州 14°')  // 显示天气文本
            .fontSize(14)  // 设置字体大小
        }
        .layoutWeight(1)  // 设置布局权重为1，使其占据剩余空间
        .justifyContent(FlexAlign.End)  // 设置子项右对齐
      }
      .width('100%')  // 设置行宽度为100%
      .padding(16)  // 设置内边距
      .backgroundColor(Color.White)  // 设置背景色为白色

      // 设备网格
      Grid() {  // 创建一个网格布局
        GridItem() {  // 创建一个网格项
          Row() {  // 创建一个行布局
            this.deviceItem($r('app.media.ic_lamp'), '灯光', '暂无灯光设备')  // 调用deviceItem方法创建灯光设备项
          }
          .onClick(() => {  // 设置点击事件
            router.pushUrl({  // 路由跳转
              url: 'pages/test2'  // 跳转到灯光页面
            }).catch((err: BusinessError) => {  // 捕获错误
              hilog.error(0x0000, 'Facility', '跳转失败: ' + JSON.stringify(err));  // 记录错误日志
            });
          })
        }

        GridItem() {  // 创建另一个网格项
          Row() {  // 创建一个行布局
            this.deviceItem($r('app.media.ic_leaf'), '环境', '暂无环境信息')  // 调用deviceItem方法创建环境设备项
          }
          .onClick(() => {  // 设置点击事件
            router.pushUrl({  // 路由跳转
              url: 'pages/Environment'  // 跳转到环境页面
            }).catch((err: BusinessError) => {  // 捕获错误
              hilog.error(0x0000, 'Facility', '跳转到环境页面失败: ' + JSON.stringify(err));  // 记录错误日志
            });
          })
        }

        GridItem() {  // 创建另一个网格项
          Row() {  // 创建一个行布局
            this.deviceItem($r('app.media.ic_camera'), '门锁监控', '查看门锁状态')  // 调用deviceItem方法创建门锁监控项
          }
          .onClick(() => {  // 设置点击事件
            router.pushUrl({  // 路由跳转
              url: 'pages/Monitor'  // 跳转到监控页面
            }).catch((err: BusinessError) => {  // 捕获错误
              hilog.error(0x0000, 'Facility', '跳转到门锁监控页面失败: ' + JSON.stringify(err));  // 记录错误日志
            });
          })
        }

        GridItem() {  // 创建另一个网格项
          Row() {  // 创建一个行布局
            this.deviceItem($r('app.media.ic_somkebell'), '烟雾报警传感器', '设备数1')  // 调用deviceItem方法创建烟雾报警项
          }
          .onClick(() => {  // 设置点击事件
            router.pushUrl({  // 路由跳转
              url: 'pages/Smokealarm'  // 跳转到烟雾报警页面
            }).catch((err: BusinessError) => {  // 捕获错误
              hilog.error(0x0000, 'Facility', '跳转到烟雾报警页面失败: ' + JSON.stringify(err));  // 记录错误日志
            });
          })
        }

        GridItem() {  // 创建另一个网格项
          this.deviceItem($r('app.media.ic_projector'), '客厅的小明 Q3 Pro', '未分配房间 | 长期离线', false)  // 调用deviceItem方法创建投影仪项，不显示箭头
        }
      }
      .columnsTemplate('1fr 1fr')  // 设置网格为两列，每列等宽
      .rowsGap(12)  // 设置行间距
      .columnsGap(12)  // 设置列间距
      .width('100%')  // 设置网格宽度为100%
      .padding(16)  // 设置内边距

      // 底部编辑按钮
      Button('编辑', { type: ButtonType.Normal })  // 创建一个按钮
        .width('40%')  // 设置按钮宽度
        .backgroundColor($r('app.color.silver_grey'))  // 设置背景色
        .fontColor($r('app.color.jet_black'))  // 设置字体颜色
        .margin({ top: 20, bottom: 30 })  // 设置外边距
    }
    .width('100%')  // 设置列宽度为100%
    .height('100%')  // 设置列高度为100%
    .backgroundColor($r('app.color.olive_green'))  // 设置背景色为橄榄绿
  }
}