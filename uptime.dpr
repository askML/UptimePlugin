library uptime;

uses
  u_params in 'u_params.pas',
  u_plugin in 'u_plugin.pas',
  u_ext_info in 'SrvPluginsSDK\u_ext_info.pas',
  u_obimp_const in 'SrvPluginsSDK\u_obimp_const.pas';

{$R *.res}

{***************************************************************}
function GetExtensionInfo: pExtensionInfo; stdcall;
begin
  Result := @ExtInfo;
end;

{***************************************************************}
function CreateExtenInstancePG(EventsPG: IEventsPG): IExtensionPG; stdcall;
begin
  Result := TUptimePlugin.Create(EventsPG);
end;

exports
  GetExtensionInfo name FUNC_NAME_EXTENSION_INFO,
  CreateExtenInstancePG name FUNC_NAME_CREATE_INSTANCE_PG;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
end.
