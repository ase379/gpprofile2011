unit gppresults.types;

interface

type
  TProgressCallback = function (percent: integer): boolean of object;
  TResPacket = record
  public
    rpTag         : byte;
    rpThread      : integer;
    rpProcID      : integer;
    rpMeasure1    : int64;
    rpMeasure2    : int64;
    rpNullOverhead: int64;
  end;

  TMeasurePointEntry = record
  public
    mpePkt : TResPacket;
    mpeName : AnsiString;
  end;

  TProcProxy = class
  public
    ppThreadID    : integer;
    ppProcID      : integer;
    ppDeadTime    : int64;
    ppStartTime   : int64;
    ppTotalTime   : int64;
    ppChildTime   : int64;

    constructor Create(threadID, procID: integer);
    destructor  Destroy; override;
    procedure   Start(pkt: TResPacket);
    procedure   Stop(var pkt: TResPacket);
    procedure   UpdateDeadTime(pkt: TResPacket);
  end;

  TActiveProcList = class
  private
    aplList : array of TProcProxy;
    aplCount: integer;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   UpdateDeadTime(pkt: TResPacket);
    procedure   Append(proxy: TProcProxy);
    procedure   Remove(proxy: TProcProxy);
    procedure   LocateLast(procID: integer; var this,parent: TProcProxy);
  end;


implementation

uses
  System.Classes, System.Sysutils;

const
  APL_QUANTUM   = 10;


{ TProcProxy }

constructor TProcProxy.Create(threadID, procID: integer);
begin
  inherited Create;
  ppThreadID  := threadID;
  ppProcID    := procID;
  ppDeadTime  := 0;
  ppStartTime := 0;
  ppTotalTime := 0;
  ppChildTime := 0;
end; { TProcProxy.Create }

destructor TProcProxy.Destroy;
begin
  inherited Destroy;
end; { TProcProxy.Destroy }

procedure TProcProxy.Start(pkt: TResPacket);
begin
  ppStartTime := pkt.rpMeasure2;
end; { TProcProxy.Start }

procedure TProcProxy.Stop(var pkt: TResPacket);
begin
  ppTotalTime := pkt.rpMeasure1-ppStartTime - ppDeadTime - ppChildTime - pkt.rpNullOverhead;
  pkt.rpNullOverhead := 2*pkt.rpNullOverhead;
  if ppTotalTime < 0 then begin // overcorrected
    ppTotalTime := 0;
    pkt.rpNullOverhead := pkt.rpNullOverhead + ppTotalTime;
  end;
end; { TProcProxy.Stop }

procedure TProcProxy.UpdateDeadTime(pkt: TResPacket);
begin
  ppDeadTime := ppDeadTime + (pkt.rpMeasure2-pkt.rpMeasure1) + pkt.rpNullOverhead;
end; { TProcProxy.UpdateDeadTime }

{ TActiveProcList }

procedure TActiveProcList.Append(proxy: TProcProxy);
begin
  if aplCount > High(aplList) then SetLength(aplList,aplCount+APL_QUANTUM);
  aplList[aplCount] := proxy;
  Inc(aplCount);
end; { TActiveProcList.Append }

constructor TActiveProcList.Create;
begin
  SetLength(aplList,APL_QUANTUM);
  aplCount := 0;
end; { TActiveProcList.Create }

destructor TActiveProcList.Destroy;
begin
  SetLength(aplList,0);
  inherited Destroy;
end; { TActiveProcList.Destroy }

procedure TActiveProcList.LocateLast(procID: integer; var this,parent: TProcProxy);
var
  i: integer;
begin
  for i := aplCount-1 downto Low(aplList) do begin
    if aplList[i].ppProcID = procID then begin
      this := aplList[i];
      if i > Low(aplList) then parent := aplList[i-1]
                          else parent := nil;
      Exit;
    end;
  end;
  this   := nil;
  parent := nil;
end; { TActiveProcList.LocateLast }

procedure TActiveProcList.Remove(proxy: TProcProxy);
var
  i: integer;
begin
  for i := aplCount-1 downto Low(aplList) do begin // should be the last, but ...
    if aplList[i] = proxy then begin
      aplCount := i;
      Exit;
    end;
  end;
  raise Exception.Create('gppResults.TActiveProcList.Remove: Entry not found!');
end; { TActiveProcList.Remove }

procedure TActiveProcList.UpdateDeadTime(pkt: TResPacket);
var
  i: integer;
begin
  for i := aplCount-1 downto Low(aplList) do
    aplList[i].UpdateDeadTime(pkt);
end; { TActiveProcList.UpdateDeadTime }
end.
