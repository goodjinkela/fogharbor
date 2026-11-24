import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { game } from '../service/GameService';

const DOMAIN: number = 0x0000;
const TAG: string = 'FogHarbor';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 全应用强制深色，保证雾港的夜不受系统主题影响
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, '%{public}s', 'Content loaded');
    });

    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      mainWindow.setWindowBackgroundColor('#080B10');
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#080B10',
        isStatusBarLightIcon: false,
        navigationBarColor: '#080B10',
        isNavigationBarLightIcon: false
      });
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'set window style failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 切到后台时兜底保存一次，防止进程被系统回收导致进度丢失 */
  onBackground(): void {
    game.persist();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  onDestroy(): void {
    game.persist();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }
}
