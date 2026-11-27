// 网关协议模型 — 与 SCI 实验 lscf_gateway (harmony_gateway.py) 对齐
// App → Gateway: {"version":1,"requestId":...,"clientId":...,"deviceId":...,"cmd":...,"args":[...],"timestamp":...}
// Gateway → App: 换行分帧 JSON，requestId 匹配
export interface GatewayRequest {
  version: number;
  requestId: string;
  clientId: string;
  deviceId: string;
  cmd: string;
  args: number[];
  timestamp: number;
}

export interface GatewayMetrics {
  adapterUs?: number;
  securePackUs?: number;
  esp32ProcessingUs?: number;
  gatewayTotalUs?: number;
}

export interface GatewayResult {
  executed?: boolean;
  value?: string;
}

export interface GatewayResponse {
  version: number;
  requestId: string;
  deviceId: string;
  status: string;
  errorCode?: string;
  message?: string;
  result?: GatewayResult;
  metrics?: GatewayMetrics;
}
