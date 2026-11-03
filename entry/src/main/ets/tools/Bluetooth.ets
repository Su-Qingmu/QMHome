/**
 * BLE 蓝牙配网服务
 * 用于扫描 ESP32 设备并通过 BLE GATT 发送 WiFi 配网信息
 *
 * 兼容: HarmonyOS API 12 ~ 26
 * 标准 ESP32 BLE 配网 UUID（基于 ESP32 NimBLE / ESP-IDF 标准协议）
 */
import { ble } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const TAG = 'Esp32Ble';

// ==================== 类型定义 ====================

/** 蓝牙设备信息 */
export interface BtDevice {
  deviceId: string;
  deviceName: string;
  rssi: number;
  connected: boolean;
}

/** 配网信息 */
export interface ProvisionInfo {
  ssid: string;
  password: string;
  /** 可选: WiFi 认证类型, 0=Open, 1=WPA2, 2=WPA3 */
  authMode?: number;
}

/** 配网状态回调 */
export type ProvisionStatusCallback = (status: string, message: string) => void;

/** 设备发现回调 */
export type DeviceFoundCallback = (device: BtDevice) => void;

/** BLE 扫描结果 */
interface ScanResult {
  deviceId: string;
  deviceName?: string;
  rssi?: number;
}

// ==================== ESP32 BLE 标准 UUID ====================

/**
 * ESP32 标准 BLE 配网服务 UUID
 *
 * 基于 ESP-IDF Provisioning 协议:
 * - Provisioning Service: 0x1818 (标准 BLE Provisioning Service)
 * - WiFi Station 特征值写入: 基于 ESP32 自定义
 *
 * 如使用 ESP32 IDF 示例中的 esp_ble_provisioning:
 *   SERVICE_UUID        = "0000FFFF-0000-1000-8000-00805F9B34FB"
 *   CHAR_WRITE_UUID     = "0000FF01-0000-1000-8000-00805F9B34FB"
 *   CHAR_NOTIFY_UUID    = "0000FF02-0000-1000-8000-00805F9B34FB"
 *
 * ⚠️ 请根据实际 ESP32 固件中的 UUID 配置修改以下值
 */
const ESP32_PROV_SERVICE_UUID = '0000FFFF-0000-1000-8000-00805F9B34FB';
const ESP32_PROV_CHAR_WRITE   = '0000FF01-0000-1000-8000-00805F9B34FB';
const ESP32_PROV_CHAR_NOTIFY  = '0000FF02-0000-1000-8000-00805F9B34FB';

// ==================== BLE 配网服务类 ====================

export class Esp32BleService {
  private isBluetoothOn: boolean = false;
  private currentDeviceId: string = '';
  private gattClient: ble.GattClientDevice | null = null;
  private discoveredDevices: Map<string, BtDevice> = new Map();
  private scanTimer: number = -1;
  private connectTimer: number = -1;

  // 回调
  private provisionStatusCallback: ProvisionStatusCallback | null = null;
  private onDeviceFoundCallback: DeviceFoundCallback | null = null;

  // UUID（可外部替换）
  serviceUuid: string = ESP32_PROV_SERVICE_UUID;
  charWriteUuid: string = ESP32_PROV_CHAR_WRITE;
  charNotifyUuid: string = ESP32_PROV_CHAR_NOTIFY;

  // ==================== 蓝牙开关 ====================

  /** 开启蓝牙并开始扫描 */
  async enableBluetooth(): Promise<boolean> {
    try {
      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
      };
      ble.startBLEScan([], scanOptions);
      this.isBluetoothOn = true;
      hilog.info(0x0000, TAG, 'BLE 扫描已开启');
      return true;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, 'BLE 扫描开启失败: %{public}s', errMsg);
      this.isBluetoothOn = false;
      return false;
    }
  }

  /** 关闭蓝牙并停止扫描 */
  async disableBluetooth(): Promise<boolean> {
    try {
      if (this.currentDeviceId) {
        await this.disconnectDevice();
      }
      this.stopScan();
      ble.stopBLEScan();
      this.isBluetoothOn = false;
      hilog.info(0x0000, TAG, 'BLE 扫描已关闭');
      return true;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, 'BLE 关闭失败: %{public}s', errMsg);
      return false;
    }
  }

  // ==================== 设备扫描 ====================

  /** 设置设备发现回调 */
  setOnDeviceFound(callback: DeviceFoundCallback): void {
    this.onDeviceFoundCallback = callback;
  }

  /** 设置配网状态回调 */
  setOnProvisionStatus(callback: ProvisionStatusCallback): void {
    this.provisionStatusCallback = callback;
  }

  /** 开始扫描 ESP32 设备 */
  startScan(scanDuration: number = 10000, onDeviceFound?: DeviceFoundCallback): void {
    if (!this.isBluetoothOn) {
      hilog.warn(0x0000, TAG, '蓝牙未开启，无法扫描');
      return;
    }

    this.discoveredDevices.clear();
    if (onDeviceFound) {
      this.onDeviceFoundCallback = onDeviceFound;
    }

    try {
      // 先移除旧监听避免重复
      ble.off('BLEDeviceFind');

      ble.on('BLEDeviceFind', (data: Array<ScanResult>) => {
        for (const device of data) {
          const deviceName: string = device.deviceName ?? '';
          const deviceId: string = device.deviceId ?? '';
          const rssi: number = device.rssi ?? 0;

          // 过滤 ESP32 及其他蓝牙设备（不过滤全部，让 UI 层做过滤）
          const btDevice: BtDevice = {
            deviceId,
            deviceName: deviceName || deviceId,
            rssi,
            connected: false,
          };

          this.discoveredDevices.set(btDevice.deviceId, btDevice);
          this.onDeviceFoundCallback?.(btDevice);
        }
      });

      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
      };
      ble.startBLEScan([], scanOptions);
      hilog.info(0x0000, TAG, '开始扫描设备...');
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, '扫描启动失败: %{public}s', errMsg);
    }

    // 扫描超时
    if (this.scanTimer !== -1) {
      clearTimeout(this.scanTimer);
    }
    this.scanTimer = setTimeout(() => {
      this.stopScan();
      hilog.info(0x0000, TAG, '扫描结束，发现 %{public}d 个设备', this.discoveredDevices.size);
    }, scanDuration);
  }

  /** 停止扫描 */
  stopScan(): void {
    try {
      ble.stopBLEScan();
    } catch (_) { /* ignore */ }
    try {
      ble.off('BLEDeviceFind');
    } catch (_) { /* ignore */ }

    if (this.scanTimer !== -1) {
      clearTimeout(this.scanTimer);
      this.scanTimer = -1;
    }
  }

  /** 获取已发现设备列表 */
  getDiscoveredDevices(): BtDevice[] {
    return Array.from(this.discoveredDevices.values());
  }

  /** 获取 ESP32 设备（按名称过滤） */
  getEsp32Devices(): BtDevice[] {
    return this.getDiscoveredDevices().filter((d) =>
      d.deviceName.startsWith('ESP32') ||
      d.deviceName.includes('Provision') ||
      d.deviceId.includes('ESP32'),
    );
  }

  // ==================== 设备连接 ====================

  /** 连接指定 BLE 设备 */
  async connectDevice(deviceId: string, timeoutMs: number = 10000): Promise<boolean> {
    try {
      hilog.info(0x0000, TAG, '正在连接设备: %{public}s', deviceId);
      this.stopScan();

      this.gattClient = ble.createGattClientDevice(deviceId);

      // 连接状态监听
      this.gattClient.on('BLEConnectionStateChange', (state: ble.BLEConnectionChangeState) => {
        hilog.info(0x0000, TAG, '连接状态变化: state=%{public}d', state.state);
        if (state.state === 0) { // 0 = DISCONNECTED
          this.handleDisconnect();
          this.provisionStatusCallback?.('disconnected', '设备已断开');
        } else if (state.state === 1) { // 1 = CONNECTED
          // 连接成功后订阅通知
          this.subscribeNotification();
        }
      });

      // 设置连接超时
      if (this.connectTimer !== -1) {
        clearTimeout(this.connectTimer);
      }
      this.connectTimer = setTimeout(() => {
        if (this.currentDeviceId !== deviceId) {
          hilog.warn(0x0000, TAG, '连接超时');
          this.provisionStatusCallback?.('timeout', '连接超时，请重试');
          this.disconnectDevice();
        }
      }, timeoutMs);

      // 发起连接
      await this.gattClient.connect();
      this.currentDeviceId = deviceId;
      this.connectTimer = -1;

      const device = this.discoveredDevices.get(deviceId);
      if (device) {
        device.connected = true;
      }

      hilog.info(0x0000, TAG, '设备连接成功: %{public}s', deviceId);
      this.provisionStatusCallback?.('connected', '设备已连接');
      return true;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, '连接失败: %{public}s', errMsg);
      this.provisionStatusCallback?.('error', '连接失败: ' + errMsg);
      return false;
    }
  }

  /** 断开设备连接 */
  async disconnectDevice(): Promise<boolean> {
    try {
      if (!this.currentDeviceId) {
        return true;
      }

      if (this.gattClient) {
        this.gattClient.off('BLEConnectionStateChange');
        this.gattClient.disconnect();
        this.gattClient = null;
      }

      this.handleDisconnect();
      hilog.info(0x0000, TAG, '设备已断开');
      return true;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, '断开失败: %{public}s', errMsg);
      return false;
    }
  }

  /** 订阅特征值通知 */
  private async subscribeNotification(): Promise<void> {
    if (!this.gattClient || !this.currentDeviceId) return;

    try {
      const notifyParam: ble.BLECharacteristic = {
        serviceUuid: this.serviceUuid,
        characteristicUuid: this.charNotifyUuid,
        characteristicValue: new ArrayBuffer(0),
        descriptors: [],
      };

      // 设置通知回调
      this.gattClient.on('BLECharacteristicChange', (result: ble.BLECharacteristic) => {
        const uint8Array = new Uint8Array(result.characteristicValue);
        const decoder = new util.TextDecoder();
        const statusStr = decoder.decodeToString(uint8Array);
        hilog.info(0x0000, TAG, '配网状态通知: %{public}s', statusStr);
        this.provisionStatusCallback?.('provision_status', statusStr);
      });

      await this.gattClient.setCharacteristicChange(notifyParam, true);
      hilog.info(0x0000, TAG, '已订阅特征值通知');
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.warn(0x0000, TAG, '订阅通知失败（部分设备不支持）: %{public}s', errMsg);
    }
  }

  // ==================== 配网写入 ====================

  /**
   * 发送配网信息 (WiFi SSID + Password)
   * 写入格式: JSON {"ssid":"xxx","password":"xxx"}
   */
  async sendProvisionInfo(provisionInfo: ProvisionInfo): Promise<boolean> {
    if (!this.currentDeviceId || !this.gattClient) {
      hilog.error(0x0000, TAG, '未连接设备');
      this.provisionStatusCallback?.('error', '设备未连接');
      return false;
    }

    try {
      const jsonData = JSON.stringify(provisionInfo);
      const dataBuffer = this.stringToArrayBuffer(jsonData);

      const charParam: ble.BLECharacteristic = {
        serviceUuid: this.serviceUuid,
        characteristicUuid: this.charWriteUuid,
        characteristicValue: dataBuffer,
        descriptors: [],
      };

      await this.gattClient.writeCharacteristicValue(charParam, ble.GattWriteType.WRITE);
      hilog.info(0x0000, TAG, '配网信息已发送: %{public}s', jsonData);
      this.provisionStatusCallback?.('sent', '配网信息已发送');
      return true;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, '配网信息发送失败: %{public}s', errMsg);
      this.provisionStatusCallback?.('error', '发送失败: ' + errMsg);
      return false;
    }
  }

  /** 发送"开始配网"指令 */
  async startProvisioning(): Promise<boolean> {
    if (!this.currentDeviceId || !this.gattClient) {
      hilog.error(0x0000, TAG, '未连接设备');
      return false;
    }

    try {
      const command = 'START_PROVISION';
      const dataBuffer = this.stringToArrayBuffer(command);

      const charParam: ble.BLECharacteristic = {
        serviceUuid: this.serviceUuid,
        characteristicUuid: this.charWriteUuid,
        characteristicValue: dataBuffer,
        descriptors: [],
      };

      await this.gattClient.writeCharacteristicValue(charParam, ble.GattWriteType.WRITE);
      hilog.info(0x0000, TAG, '配网指令已发送');
      this.provisionStatusCallback?.('provisioning', '配网进行中...');
      return true;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      hilog.error(0x0000, TAG, '配网指令发送失败: %{public}s', errMsg);
      return false;
    }
  }

  // ==================== 状态查询 ====================

  /** 是否已连接 */
  isConnected(): boolean {
    return this.currentDeviceId !== '';
  }

  /** 获取当前连接设备 ID */
  getCurrentDeviceId(): string {
    return this.currentDeviceId;
  }

  /** 获取蓝牙状态 */
  getBluetoothState(): boolean {
    return this.isBluetoothOn;
  }

  // ==================== 内部方法 ====================

  private handleDisconnect(): void {
    this.currentDeviceId = '';
    this.gattClient = null;
    this.discoveredDevices.forEach((device) => {
      device.connected = false;
    });
  }

  private stringToArrayBuffer(str: string): ArrayBuffer {
    const buffer = new ArrayBuffer(str.length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < str.length; i++) {
      uint8Array[i] = str.charCodeAt(i);
    }
    return buffer;
  }
}

// 导出单例
export const esp32BleService = new Esp32BleService();
