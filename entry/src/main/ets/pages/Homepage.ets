import Dailylife from '../pages/view/Dailylife'
import Facility from '../pages/view/Facility'
import MineContent from '../pages/view/MineContent'

@Entry
@Component
struct Homepage {
  @State selectIndex: number = 0

  @Builder
  TabBarBuilder(index: number, normalIcon: ResourceStr, text: string) {
    Column() {
      Image(normalIcon)
        .width(20)
        .fillColor(this.selectIndex == index ? $r('app.color.forest_green') : $r('app.color.jet_black'))
      Text(text)
        .fontSize(10)
        .fontColor(this.selectIndex == index ? $r('app.color.forest_green') : $r('app.color.jet_black'))
    }
    .onClick(() => {
      this.selectIndex = index
    })
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.selectIndex
    }) {
      // 设备主页
      TabContent() {
        Facility()  // 这里实际使用Facility组件
      }
      .tabBar(this.TabBarBuilder(
        0,
        $r('app.media.ic_scene_home'),
        "设备"
      ))

      // 生活页
      TabContent() {
        Dailylife()  // 这里实际使用Dailylife组件
      }
      .tabBar(this.TabBarBuilder(
        1,
        $r('app.media.ic_public_favor_filled'),
        "生活"
      ))

       //我的页面
       TabContent() {
         MineContent()
       }
       .tabBar(this.TabBarBuilder(
         2,
         $r('app.media.ic_public_contacts_filled'),
         "我的"
       ))
    }
    .onChange((index: number) => {
      this.selectIndex = index
    })
  }
}