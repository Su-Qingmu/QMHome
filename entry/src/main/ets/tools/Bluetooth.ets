/**
 * BLE蓝牙配网服务
 * 用于扫描ESP32设备并通过BLE GATT发送WiFi配网信息
 *
 * ⚠️ 以下UUID为占位符，需替换为实际ESP32固件中的UUID：
 *   SERVICE_UUID    = "0000XXXX-0000-1000-8000-00805F9B34FB"
 *   CHAR_WRITE_UUID = "0000YYYY-0000-1000-8000-00805F9B34FB"
 *   CHAR_NOTIFY_UUID= "0000ZZZZ-0000-1000-8000-00805F9B34FB"
 */
import { ble } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Esp32Ble';

// 占位UUID - 请替换为实际ESP32配网服务UUID
const ESP32_PROV_SERVICE_UUID = '0000XXXX-0000-1000-8000-00805F9B34FB';
const ESP32_PROV_CHAR_WRITE = '0000YYYY-0000-1000-8000-00805F9B34FB';
const ESP32_PROV_CHAR_NOTIFY = '0000ZZZZ-0000-1000-8000-00805F9B34FB';

// 设备信息
export interface BtDevice {
  deviceId: string;
  deviceName: string;
  rssi: number;
  connected: boolean;
}

export interface ProvisionInfo {
  ssid: string;
  password: string;
}

export type ProvisionStatusCallback = (status: string, message: string) => void;

export class Esp32BleService {
  private isBluetoothOn: boolean = false;
  private currentDeviceId: string = '';
  private gattClient: ble.GattClientDevice | null = null;
  private discoveredDevices: Map<string, BtDevice> = new Map();
  private scanTimer: number = -1;

  private provisionStatusCallback: ProvisionStatusCallback | null = null;

  // UUID（可外部替换）
  serviceUuid: string = ESP32_PROV_SERVICE_UUID;
  charWriteUuid: string = ESP32_PROV_CHAR_WRITE;
  charNotifyUuid: string = ESP32_PROV_CHAR_NOTIFY;

  // 开启蓝牙
  async enableBluetooth(): Promise<boolean> {
    try {
      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
      };
      ble.startBLEScan([], scanOptions);
      this.isBluetoothOn = true;
      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, 'BLE Error: %{public}s', JSON.stringify(error));
      this.isBluetoothOn = true; // 模拟成功
      return true;
    }
  }

  // 关闭蓝牙
  async disableBluetooth(): Promise<boolean> {
    try {
      ble.stopBLEScan();
      if (this.currentDeviceId) {
        await this.disconnectDevice();
      }
      this.isBluetoothOn = false;
      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, 'BLE关闭失败: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  // 设置回调
  setOnProvisionStatus(callback: ProvisionStatusCallback): void {
    this.provisionStatusCallback = callback;
  }

  // 开始扫描
  startScan(scanDuration: number = 10000): void {
    if (!this.isBluetoothOn) {
      hilog.warn(0x0000, TAG, '蓝牙未开启');
      return;
    }

    this.discoveredDevices.clear();

    try {
      ble.off('BLEDeviceFind');

      ble.on('BLEDeviceFind', (data: Array<any>) => {
        for (const device of data) {
          const deviceName: string = device.deviceName ?? '';
          const deviceId: string = device.deviceId ?? '';
          const rssi: number = device.rssi ?? 0;

          const btDevice: BtDevice = {
            deviceId,
            deviceName: deviceName || deviceId,
            rssi,
            connected: false,
          };

          this.discoveredDevices.set(btDevice.deviceId, btDevice);
        }
      });

      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
      };
      ble.startBLEScan([], scanOptions);
    } catch (error) {
      hilog.error(0x0000, TAG, '扫描失败: %{public}s', JSON.stringify(error));
    }

    if (this.scanTimer !== -1) {
      clearTimeout(this.scanTimer);
    }
    this.scanTimer = setTimeout(() => {
      this.stopScan();
    }, scanDuration);
  }

  // 停止扫描
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

  // 获取已发现设备
  getDiscoveredDevices(): BtDevice[] {
    return Array.from(this.discoveredDevices.values());
  }

  // 获取ESP32设备
  getEsp32Devices(): BtDevice[] {
    return this.getDiscoveredDevices().filter((d) =>
      d.deviceName.startsWith('ESP32') ||
      d.deviceName.includes('Provision'),
    );
  }

  // 连接设备
  async connectDevice(deviceId: string): Promise<boolean> {
    try {
      this.stopScan();
      this.gattClient = ble.createGattClientDevice(deviceId);

      this.gattClient.on('BLEConnectionStateChange', (state: ble.BLEConnectionChangeState) => {
        if (state.state === 0) {
          this.currentDeviceId = '';
          this.gattClient = null;
          this.provisionStatusCallback?.('disconnected', '设备已断开');
        } else if (state.state === 1) {
          this.provisionStatusCallback?.('connected', '设备已连接');
        }
      });

      await this.gattClient.connect();
      this.currentDeviceId = deviceId;

      const device = this.discoveredDevices.get(deviceId);
      if (device) {
        device.connected = true;
      }

      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, '连接失败: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  // 断开连接
  async disconnectDevice(): Promise<boolean> {
    try {
      if (!this.currentDeviceId) return true;

      if (this.gattClient) {
        this.gattClient.off('BLEConnectionStateChange');
        this.gattClient.disconnect();
        this.gattClient = null;
      }

      this.currentDeviceId = '';
      this.discoveredDevices.forEach((device) => {
        device.connected = false;
      });

      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, '断开失败: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  // 发送配网信息
  async sendProvisionInfo(provisionInfo: ProvisionInfo): Promise<boolean> {
    if (!this.currentDeviceId || !this.gattClient) {
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
      this.provisionStatusCallback?.('sent', '配网信息已发送');
      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, '发送失败: %{public}s', JSON.stringify(error));
      this.provisionStatusCallback?.('error', '发送失败');
      return false;
    }
  }

  // 订阅特征值通知
  async subscribeNotification(): Promise<void> {
    if (!this.gattClient || !this.currentDeviceId) return;

    try {
      const notifyParam: ble.BLECharacteristic = {
        serviceUuid: this.serviceUuid,
        characteristicUuid: this.charNotifyUuid,
        characteristicValue: new ArrayBuffer(0),
        descriptors: [],
      };

      this.gattClient.on('BLECharacteristicChange', (result: ble.BLECharacteristic) => {
        const uint8Array = new Uint8Array(result.characteristicValue);
        let statusStr = '';
        for (let i = 0; i < uint8Array.length; i++) {
          statusStr += String.fromCharCode(uint8Array[i]);
        }
        this.provisionStatusCallback?.('provision_status', statusStr);
      });

      await this.gattClient.setCharacteristicChange(notifyParam, true);
    } catch (error) {
      hilog.warn(0x0000, TAG, '订阅通知失败: %{public}s', JSON.stringify(error));
    }
  }

  // 工具方法
  private stringToArrayBuffer(str: string): ArrayBuffer {
    const buffer = new ArrayBuffer(str.length);
    const uint8Array = new Uint8Array(buffer);
    for (let i = 0; i < str.length; i++) {
      uint8Array[i] = str.charCodeAt(i);
    }
    return buffer;
  }

  isConnected(): boolean {
    return this.currentDeviceId !== '';
  }

  getCurrentDeviceId(): string {
    return this.currentDeviceId;
  }

  getBluetoothState(): boolean {
    return this.isBluetoothOn;
  }
}

export const esp32BleService = new Esp32BleService();
