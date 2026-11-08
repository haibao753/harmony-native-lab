import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;
const TAG = 'FaceLab';

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | undefined = undefined;
  private mainWindow: window.Window | undefined = undefined;
  private stageLifecycleCallback:
    ((state: window.WindowStageLifecycleEventType) => void) | undefined = undefined;
  private windowEventCallback: ((state: window.WindowEventType) => void) | undefined = undefined;
  private windowStatusCallback: ((status: window.WindowStatusType) => void) | undefined = undefined;
  private windowVisibilityCallback: ((visible: boolean) => void) | undefined = undefined;
  private eventHistory: string[] = [];

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate('faceLabWindowLifecycle', 'UNKNOWN');
    AppStorage.setOrCreate('faceLabWindowFocus', 'UNKNOWN');
    AppStorage.setOrCreate('faceLabWindowMode', 'UNKNOWN');
    AppStorage.setOrCreate('faceLabWindowVisible', false);
    AppStorage.setOrCreate('faceLabWindowEventLog', '');
    hilog.info(DOMAIN, TAG, 'FaceLab onCreate');
    this.recordWindowEvent('UIABILITY_CREATED');
  }

  onForeground(): void {
    this.recordWindowEvent('UIABILITY_FOREGROUND');
  }

  onBackground(): void {
    AppStorage.setOrCreate('faceLabWindowLifecycle', 'HIDDEN');
    AppStorage.setOrCreate('faceLabWindowVisible', false);
    this.recordWindowEvent('UIABILITY_BACKGROUND');
  }

  onDestroy(): void {
    this.disposeWindowListeners();
    hilog.info(DOMAIN, TAG, 'FaceLab onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
    this.stageLifecycleCallback = (state: window.WindowStageLifecycleEventType) => {
      const label = this.stageLifecycleLabel(state);
      AppStorage.setOrCreate('faceLabWindowLifecycle', label);
      if (label === 'HIDDEN') {
        AppStorage.setOrCreate('faceLabWindowVisible', false);
      } else if (label === 'SHOWN' || label === 'RESUMED' || label === 'PAUSED') {
        AppStorage.setOrCreate('faceLabWindowVisible', true);
      }
      this.recordWindowEvent('STAGE_' + label);
    };

    try {
      windowStage.on('windowStageLifecycleEvent', this.stageLifecycleCallback);
    } catch (error) {
      this.recordWindowEvent('STAGE_LISTENER_ERROR');
      hilog.error(DOMAIN, TAG, 'Failed to register WindowStage lifecycle listener: %{public}s',
        JSON.stringify(error));
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load page: %{public}s', JSON.stringify(err));
        this.recordWindowEvent('LOAD_CONTENT_ERROR');
        return;
      }

      try {
        this.mainWindow = windowStage.getMainWindowSync();
        this.windowEventCallback = (state: window.WindowEventType) => {
          if (state === window.WindowEventType.WINDOW_ACTIVE) {
            AppStorage.setOrCreate('faceLabWindowFocus', 'ACTIVE');
          } else if (state === window.WindowEventType.WINDOW_INACTIVE) {
            AppStorage.setOrCreate('faceLabWindowFocus', 'INACTIVE');
          } else if (state === window.WindowEventType.WINDOW_SHOWN) {
            AppStorage.setOrCreate('faceLabWindowVisible', true);
          } else if (state === window.WindowEventType.WINDOW_HIDDEN ||
            state === window.WindowEventType.WINDOW_DESTROYED) {
            AppStorage.setOrCreate('faceLabWindowVisible', false);
          }
          this.recordWindowEvent('WINDOW_' + this.windowEventLabel(state));
        };
        this.mainWindow.on('windowEvent', this.windowEventCallback);

        this.windowStatusCallback = (status: window.WindowStatusType) => {
          AppStorage.setOrCreate('faceLabWindowMode', this.windowStatusLabel(status));
          this.recordWindowEvent('MODE_' + this.windowStatusLabel(status));
        };
        this.mainWindow.on('windowStatusDidChange', this.windowStatusCallback);

        this.windowVisibilityCallback = (visible: boolean) => {
          AppStorage.setOrCreate('faceLabWindowVisible', visible);
          this.recordWindowEvent(visible ? 'WINDOW_VISIBLE' : 'WINDOW_NOT_VISIBLE');
        };
        this.mainWindow.on('windowVisibilityChange', this.windowVisibilityCallback);

        this.refreshWindowSnapshot();
        this.recordWindowEvent('MAIN_WINDOW_READY');
      } catch (error) {
        this.recordWindowEvent('MAIN_WINDOW_LISTENER_ERROR');
        hilog.error(DOMAIN, TAG, 'Failed to initialize main window diagnostics: %{public}s',
          JSON.stringify(error));
      }
    });
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    if (this.windowStage === windowStage) {
      this.disposeWindowListeners();
      this.windowStage = undefined;
    }
  }

  onWindowStageDestroy(): void {
    this.windowStage = undefined;
  }

  private refreshWindowSnapshot(): void {
    if (this.mainWindow === undefined) {
      return;
    }
    try {
      AppStorage.setOrCreate('faceLabWindowMode',
        this.windowStatusLabel(this.mainWindow.getWindowStatus()));
      AppStorage.setOrCreate('faceLabWindowVisible', this.mainWindow.isWindowShowing());
      AppStorage.setOrCreate('faceLabWindowFocus',
        this.mainWindow.isFocused() ? 'ACTIVE' : 'INACTIVE');
    } catch (error) {
      this.recordWindowEvent('WINDOW_SNAPSHOT_ERROR');
      hilog.warn(DOMAIN, TAG, 'Window snapshot unavailable: %{public}s', JSON.stringify(error));
    }
  }

  private stageLifecycleLabel(state: window.WindowStageLifecycleEventType): string {
    if (state === window.WindowStageLifecycleEventType.SHOWN) {
      return 'SHOWN';
    }
    if (state === window.WindowStageLifecycleEventType.RESUMED) {
      return 'RESUMED';
    }
    if (state === window.WindowStageLifecycleEventType.PAUSED) {
      return 'PAUSED';
    }
    if (state === window.WindowStageLifecycleEventType.HIDDEN) {
      return 'HIDDEN';
    }
    return 'UNKNOWN';
  }

  private windowEventLabel(state: window.WindowEventType): string {
    if (state === window.WindowEventType.WINDOW_SHOWN) {
      return 'SHOWN';
    }
    if (state === window.WindowEventType.WINDOW_ACTIVE) {
      return 'ACTIVE';
    }
    if (state === window.WindowEventType.WINDOW_INACTIVE) {
      return 'INACTIVE';
    }
    if (state === window.WindowEventType.WINDOW_HIDDEN) {
      return 'HIDDEN';
    }
    if (state === window.WindowEventType.WINDOW_DESTROYED) {
      return 'DESTROYED';
    }
    return 'UNKNOWN';
  }

  private windowStatusLabel(status: window.WindowStatusType): string {
    if (status === window.WindowStatusType.SPLIT_SCREEN) {
      return 'SPLIT_SCREEN';
    }
    if (status === window.WindowStatusType.FLOATING) {
      return 'FLOATING';
    }
    if (status === window.WindowStatusType.MAXIMIZE) {
      return 'MAXIMIZE';
    }
    if (status === window.WindowStatusType.MINIMIZE) {
      return 'MINIMIZE';
    }
    if (status === window.WindowStatusType.FULL_SCREEN) {
      return 'FULL_SCREEN';
    }
    return 'UNDEFINED';
  }

  private recordWindowEvent(label: string): void {
    const timestamp = new Date().toISOString().substring(11, 19);
    this.eventHistory.push(timestamp + ' ' + label);
    if (this.eventHistory.length > 8) {
      this.eventHistory.shift();
    }
    AppStorage.setOrCreate('faceLabWindowEventLog', this.eventHistory.join('\n'));
    hilog.info(DOMAIN, TAG, 'Window probe: ' + label);
  }

  private disposeWindowListeners(): void {
    if (this.mainWindow !== undefined) {
      try {
        if (this.windowEventCallback !== undefined) {
          this.mainWindow.off('windowEvent', this.windowEventCallback);
        }
        if (this.windowStatusCallback !== undefined) {
          this.mainWindow.off('windowStatusDidChange', this.windowStatusCallback);
        }
        if (this.windowVisibilityCallback !== undefined) {
          this.mainWindow.off('windowVisibilityChange', this.windowVisibilityCallback);
        }
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Failed to remove main window listeners: %{public}s',
          JSON.stringify(error));
      }
    }
    if (this.windowStage !== undefined && this.stageLifecycleCallback !== undefined) {
      try {
        this.windowStage.off('windowStageLifecycleEvent', this.stageLifecycleCallback);
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'Failed to remove WindowStage listener: %{public}s',
          JSON.stringify(error));
      }
    }
    this.mainWindow = undefined;
    this.windowEventCallback = undefined;
    this.windowStatusCallback = undefined;
    this.windowVisibilityCallback = undefined;
    this.stageLifecycleCallback = undefined;
  }
}
