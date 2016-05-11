unit u_params;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  Winapi.TlHelp32, u_ext_info, u_obimp_const;

const
  CONF_NAME = 'config.ini';

  //filling plugin parameters
  ExtParams: TExtParamsPG = ( ListenTextMsgs: False; );

  ExtInfo: TExtensionInfo = (
    ExtType    : EXT_TYPE_PLUGIN;
    ExtUUID    : ($F8,$48,$D9,$CB,$54,$76,$42,$82,$82,$DB,$D0,$20,$3B,$35,$78,$FD); //MUST BE unique for every new extension/plugin
    ExtName    : 'Uptime server info plugin';
    ExtVer     : '0.0.1';
    ExtAuthor  : 'alexey-m';
    ExtInfoURL : 'https://alexey-m.ru';
    ExtParams  : @ExtParams;
    ExtTimer   : True;
  );

  FTP_SRV_NAME = 'BimFtSrv32.exe';

type
  TConfig = record
    token: String;
    url: String;
    path: String;
    pathLog: String;
    srvVer: String;
    updateTime: UInt;
    startTime: UInt;
    idTimer: UIntPtr;
    enable: Boolean;
  end;



//helpful functions
procedure OutDebugStr(s: string);
procedure LogToFile(FileName: string; Data: string);
procedure InitConfig(AEventsPG: IEventsPG);
function CmpStr(Str1, Str2: String): Boolean;
function getPIdBimFtSrv(): UInt;
function getStartTimeProc(const procId: THandle): UInt;

var
  config: TConfig;


implementation

{*****************************************************************}
procedure OutDebugStr(s: string);
begin
  OutputDebugString(PChar(s));
end;

{*******************************************************************}
procedure LogToFile(FileName: string; Data: string);
var aFS: TFileStream;
    BOM: TBytes;
begin
  aFS := nil;
  try

  if FileExists(FileName) then
    aFS := TFileStream.Create(FileName, fmOpenWrite or fmShareDenyWrite)
  else
  begin
    aFS := TFileStream.Create(FileName, fmCreate);

    if Assigned(aFS) then
    begin
      BOM := TEncoding.Unicode.GetPreamble;
      aFS.Position := 0;
      aFS.Write(BOM[0], Length(BOM));
    end;
  end;

  except
    if Assigned(aFS) then aFS.Free;
    Exit;
  end;

  aFS.Position := aFS.Size;

  try
    Data := Data + #13#10;

    SetLength(Data, Length(Data));
    aFS.Write(Data[1], Length(Data) * SizeOf(Char));
  finally
    aFS.Free;
  end;
end;

function DateTimeToUnix(ConvDate: TDateTime): Longint;
const
  // Sets UnixStartDate to TDateTime of 01/01/1970
  UnixStartDate: TDateTime = 25569.0;
begin
  Result := Round((ConvDate - UnixStartDate) * 86400);
end;

function WindowsTickToUnixSeconds(windowsTicks: UInt64): UInt;
const
  WINDOWS_TICK = 10000000;
  SEC_TO_UNIX_EPOCH = 11644473600;
begin
  Result:= windowsTicks div WINDOWS_TICK - SEC_TO_UNIX_EPOCH;
end;

procedure InitConfig(AEventsPG: IEventsPG);
var
  cfgFile: String;
  buffer: array[0..MAX_PATH] of WideChar;
  srvInfo: TExtServerInfo;
  ini: TIniFile;
begin
  config.startTime:= DateTimeToUnix(Now());

  GetModuleFileName(HInstance, @buffer, sizeOf(buffer));

  config.path:= ExtractFilePath(PChar(@buffer));
  cfgFile:= config.path + CONF_NAME;
  config.enable:= False;

  AEventsPG.GetServerInfo(srvInfo);

  config.srvVer:= Format('%d.%d.%d.%d', [srvInfo.VerMajor, srvInfo.VerMinor, srvInfo.VerRelease, srvInfo.VerBuild]);
  config.pathLog:= srvInfo.PathLogFiles;

  if FileExists(cfgFile) then begin

    ini:= TIniFile.Create(cfgFile); try

      config.token:= ini.ReadString('main', 'token', '');
      config.url:= ini.ReadString('main', 'url', 'http://localhost/uptime');
      config.updateTime:= ini.ReadInteger('main', 'timeUpdate',  180);
      config.enable:= ini.ReadBool('main', 'enable',  False);
    finally
      ini.Free;
    end;
  end;

end;



function getStartTimeProc(const procId: THandle): UInt;
var
  hProcess: THandle;
  lpCreationTime, lpExitTime, lpKernelTime, lpUserTime: TFileTime;
begin
  Result:= 0;

  hProcess:= OpenProcess(PROCESS_QUERY_INFORMATION, false, procId);

  if (hProcess <> 0) then try

    if GetProcessTimes(hProcess, lpCreationTime, lpExitTime, lpKernelTime, lpUserTime) then begin

      Result:= WindowsTickToUnixSeconds(PUInt64(@lpCreationTime)^);
    end;

  finally
    CloseHandle(hProcess);
  end;

end;

function getPIdBimFtSrv(): UInt;
var
  hSnapShot: THandle;
  ProcInfo: TProcessEntry32;
  exeFile: String;
begin
  Result:= 0;

  hSnapShot:= CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (hSnapShot <> INVALID_HANDLE_VALUE) then try

    ProcInfo.dwSize:= SizeOf(ProcInfo);

    if (Process32First(hSnapshot, ProcInfo)) then
    repeat

      exeFile:= ExtractFileName(ProcInfo.szExeFile);

      if CmpStr(FTP_SRV_NAME, exeFile) then begin

        Result:= getStartTimeProc(procInfo.th32ProcessID);
        Break;
      end;

    until not Process32Next(hSnapShot, ProcInfo);

  finally
    CloseHandle(hSnapShot);
  end;
end;


function CmpStr(Str1, Str2: String): Boolean;
begin
   Result:= lstrcmpi(PChar(Str1), PChar(Str2)) = 0;
end;




end.
