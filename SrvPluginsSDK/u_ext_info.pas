unit u_ext_info;

interface

uses Windows, u_obimp_const;

const
  //============================================
  //dll exported functions names
  FUNC_NAME_EXTENSION_INFO     = 'GetExtensionInfo_v2';
  FUNC_NAME_CREATE_INSTANCE_PG = 'CreateExtenInstancePG_v2';

  //============================================
  //Available extension types:
  EXT_TYPE_TRANSPORT = $0001;
  EXT_TYPE_PLUGIN    = $0002;

  EXT_TYPE_MAX       = $0002;


type
  //common extension information
  TExtensionInfo = record
    ExtType    : Word;
    ExtUUID    : array[0..15] of Byte;
    ExtName    : WideString; //must not be empty
    ExtVer     : WideString;
    ExtAuthor  : WideString;
    ExtInfoURL : WideString;
    ExtParams  : Pointer;    //according ExtType
    ExtTimer   : Boolean;    //extensions wants to receive timer ticks for instances, every ~1000 msecs will be called TimerTick function
  end;
  pExtensionInfo = ^TExtensionInfo;


  ///////////////////////////////////////////////////////////////////////////////
  /// PLUGIN extension
  ///////////////////////////////////////////////////////////////////////////////

  //plugin extension parameters
  TExtParamsPG = record
    ListenTextMsgs: Boolean;
  end;
  pExtParamsPG = ^TExtParamsPG;


  TExtServerInfo = record
    VerMajor     : Word;
    VerMinor     : Word;
    VerRelease   : Word;
    VerBuild     : Word;
    PathUserDB   : WideString;
    PathLogFiles : WideString;
  end;
  pExtServerInfo = ^TExtServerInfo;


  TExtPlugTextMsg = record
    AccSender      : WideString;
    AccRcver       : WideString;
    MsgType        : DWord;
    MsgText        : WideString;
    AckRequired    : Boolean;    //delivery report from receiver required
    MsgEncrypted   : Boolean;    //if message is encrypted then it will be base64 encoded, but anyway it can't be decryted
    SystemMsg      : Boolean;    //system message flag
    SystemMsgPos   : Byte;       //system message popup position (0 - default, 1 - screen center)
    MultipleMsg    : Boolean;    //multiple message flag
    RcverOffline   : Boolean;    //receiver is offline at message sending moment
    TranspOwnerAcc : WideString; //transport owner account name if message was send to transport
    TranspUUIDHex  : WideString; //transport UUID in hex if message was send to transport
  end;
  pExtPlugTextMsg = ^TExtPlugTextMsg;


  //plugin extension interface
  IExtensionPG = interface
    procedure TimerTick; stdcall;
    procedure NotifyTextMsg(const ExtPlugTextMsg: TExtPlugTextMsg); stdcall;
  end;

  //plugin events interface
  IEventsPG = interface
    procedure GetServerInfo(var ServerInfo: TExtServerInfo); stdcall;
  end;

implementation

end.
