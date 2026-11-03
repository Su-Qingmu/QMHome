/**
 * 数据持久化工具类
 * 基于 Preferences（首选项）实现应用配置的本地存储
 *
 * 兼容: HarmonyOS API 12 ~ 26
 * 使用: @kit.ArkData 中的 data.preferences
 */
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const STORE_NAME = 'harmtwo_preferences';

/** 存储键名常量 */
export const PrefKeys = {
  /** TCP 目标地址 */
  TCP_ADDRESS: 'tcp_address',
  /** TCP 目标端口 */
  TCP_PORT: 'tcp_port',
  /** 灯光最后亮度 */
  LIGHT_LAST_BRIGHTNESS: 'light_last_bright',
  /** 灯光最后色温 */
  LIGHT_LAST_TEMPERATURE: 'light_last_temp',
  /** 灯光开关状态 */
  LIGHT_POWER_STATE: 'light_power_state',
  /** 深色模式偏好: 'auto' | 'light' | 'dark' */
  THEME_MODE: 'theme_mode',
  /** 已配网设备列表 JSON */
  PAIRED_DEVICES: 'paired_devices',
  /** 场景配置 JSON */
  SCENE_CONFIGS: 'scene_configs',
} as const;

export class PreferencesUtil {
  private static instance: PreferencesUtil;
  private prefStore: preferences.Preferences | null = null;
  private isReady: boolean = false;

  private constructor() {}

  /** 获取单例 */
  static getInstance(): PreferencesUtil {
    if (!PreferencesUtil.instance) {
      PreferencesUtil.instance = new PreferencesUtil();
    }
    return PreferencesUtil.instance;
  }

  /** 初始化（需传入 Context，在 EntryAbility 中调用） */
  async init(context: Context): Promise<void> {
    if (this.isReady) return;
    try {
      this.prefStore = await preferences.getPreferences(context, STORE_NAME);
      this.isReady = true;
      console.log('PreferencesUtil 初始化成功');
    } catch (error) {
      const msg = error instanceof Error ? error.message : JSON.stringify(error);
      console.error('PreferencesUtil 初始化失败: ' + msg);
    }
  }

  /** 确保已初始化 */
  private checkReady(): void {
    if (!this.isReady || !this.prefStore) {
      throw new Error('PreferencesUtil 未初始化，请先调用 init()');
    }
  }

  // ==================== 字符串读写 ====================

  /** 获取字符串值 */
  async getString(key: string, defaultValue: string = ''): Promise<string> {
    this.checkReady();
    try {
      const val = await this.prefStore!.get(key, defaultValue);
      return val as string;
    } catch (error) {
      console.error(`读取 ${key} 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /** 设置字符串值 */
  async setString(key: string, value: string): Promise<void> {
    this.checkReady();
    try {
      await this.prefStore!.put(key, value);
      await this.prefStore!.flush();
    } catch (error) {
      console.error(`写入 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  // ==================== 数字读写 ====================

  /** 获取数字值 */
  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    this.checkReady();
    try {
      const val = await this.prefStore!.get(key, defaultValue);
      return val as number;
    } catch (error) {
      console.error(`读取 ${key} 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /** 设置数字值 */
  async setNumber(key: string, value: number): Promise<void> {
    this.checkReady();
    try {
      await this.prefStore!.put(key, value);
      await this.prefStore!.flush();
    } catch (error) {
      console.error(`写入 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  // ==================== 布尔读写 ====================

  /** 获取布尔值 */
  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    this.checkReady();
    try {
      const val = await this.prefStore!.get(key, defaultValue);
      return val as boolean;
    } catch (error) {
      console.error(`读取 ${key} 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /** 设置布尔值 */
  async setBoolean(key: string, value: boolean): Promise<void> {
    this.checkReady();
    try {
      await this.prefStore!.put(key, value);
      await this.prefStore!.flush();
    } catch (error) {
      console.error(`写入 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  // ==================== JSON 读写 ====================

  /** 获取 JSON 对象 */
  async getObject<T>(key: string, defaultValue: T | null = null): Promise<T | null> {
    this.checkReady();
    try {
      const val = await this.prefStore!.get(key, '');
      if (val === '') return defaultValue;
      return JSON.parse(val as string) as T;
    } catch (error) {
      console.error(`读取 ${key} JSON 失败: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }

  /** 设置 JSON 对象 */
  async setObject<T>(key: string, value: T): Promise<void> {
    this.checkReady();
    try {
      const jsonStr = JSON.stringify(value);
      await this.prefStore!.put(key, jsonStr);
      await this.prefStore!.flush();
    } catch (error) {
      console.error(`写入 ${key} JSON 失败: ${JSON.stringify(error)}`);
    }
  }

  // ==================== 删除与清除 ====================

  /** 删除指定键 */
  async delete(key: string): Promise<void> {
    this.checkReady();
    try {
      await this.prefStore!.delete(key);
      await this.prefStore!.flush();
    } catch (error) {
      console.error(`删除 ${key} 失败: ${JSON.stringify(error)}`);
    }
  }

  /** 清除所有数据 */
  async clear(): Promise<void> {
    this.checkReady();
    try {
      await this.prefStore!.clear();
      await this.prefStore!.flush();
    } catch (error) {
      console.error(`清除数据失败: ${JSON.stringify(error)}`);
    }
  }
}

/** 导出的便捷单例 */
export const prefUtil = PreferencesUtil.getInstance();
