unit u_plugin;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Net.URLClient,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  u_ext_info, u_obimp_const, u_params;

type
  // Uptime plugin class
  TUptimePlugin = class(TInterfacedObject, IExtensionPG)
  private
    FTick: Integer;
  public
    EventsPG : IEventsPG;
    constructor Create(AEventsPG: IEventsPG);
    destructor  Destroy; override;

    {==== Interface functions ====}
    procedure TimerTick; stdcall;
    procedure NotifyTextMsg(const ExtPlugTextMsg: TExtPlugTextMsg); stdcall;
  end;



implementation

{ TUptimePlugin }

constructor TUptimePlugin.Create(AEventsPG: IEventsPG);
var
  srvInfo: TExtServerInfo;
  sFileLog, sLogStr: string;
begin
  FTick:= 0;
  //save events interface, will be used for plugin callbacks
  EventsPG := AEventsPG;
  //get server info, there we can find logs folder path
  EventsPG.GetServerInfo(srvInfo);

  InitConfig(EventsPG);

  sFileLog:= IncludeTrailingPathDelimiter(srvInfo.PathLogFiles) + 'uptime_' + FormatDateTime('yyyy"-"mm"-"dd', Now) + '.txt';

  sLogStr:= Format('Bimoid server: %d.%d.%d.%d', [srvInfo.VerMajor, srvInfo.VerMinor, srvInfo.VerRelease, srvInfo.VerBuild]);
  sLogStr:= sLogStr + sLineBreak + Format('%s %s %s %d %s',
    [
      config.token,
      config.url,
      config.path,
      config.updateTime,
      BoolToStr(config.enable, true)
     ]);

  //write log to file
  LogToFile(sFileLog, sLogStr);
end;


destructor TUptimePlugin.Destroy;
begin
  inherited;
end;


procedure TUptimePlugin.TimerTick;
var
  data: String;
  http: TNetHTTPClient;
begin
  // Âûחמג ךאזהûו 100לס
  Inc(FTick);

  if(FTick > config.updateTime * 10) then begin

    if (config.enable) then begin

      data:= Format('%s?token=%s&startTime=%d&startFtTime=%d&ver=%s',
        [config.url, config.token, config.startTime, getPIdBimFtSrv, config.srvVer]);


      http:= TNetHTTPClient.Create(nil);

      if Assigned(http) then try
        http.Get(data);
      finally
        http.Free;
      end;

    end;

    FTick:= 0;
  end;

end;

procedure TUptimePlugin.NotifyTextMsg(const ExtPlugTextMsg: TExtPlugTextMsg);
begin

end;


end.
