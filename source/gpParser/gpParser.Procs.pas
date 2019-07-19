unit gpParser.Procs;

interface

uses
  gppTree,System.SysUtils;

type
  TProcSetThreadName = class
  const
  public
    tpstnPos: Integer;
    tpstnWithSelf: string;
  end;

  TProcSetThreadNameList = class(TRootNode<TProcSetThreadName>)
  private
    constructor Create; reintroduce;
  protected
    function GetLookupKey(const aValue : TProcSetThreadName) : string; override;
  public
    procedure AddPosition(const aPos: Cardinal; const aSelfBuffer: string);
  end;


  TProc = class
  private
    prName: String;
    fHeaderLineNum: Integer;
    fStartOffset: Integer;
    fStartLineNum: Integer;
    fEndOffset: Integer;
    fEndLineNum: Integer;
    fInstrumented: boolean;
    fInitial: boolean;
    fCmtEnterBegin: Integer;
    fCmtEnterEnd: Integer;
    fCmtExitBegin: Integer;
    fCmtExitEnd: Integer;
    fPureAsm: boolean;
    fSetThreadNames: TProcSetThreadNameList;
    function GetName: String;
  public
    constructor Create(procName: string; offset: Integer = 0;
      lineNum: Integer = 0; headerLineNum: Integer = 0);
    destructor Destroy; override;
    // the unicode name
    property Name : String read GetName;
    property prHeaderLineNum: integer read fHeaderLineNum;
    property prStartOffset: Integer read fStartOffset;
    property prStartLineNum: Integer read fStartLineNum;
    property prEndOffset: Integer read fEndOffset;
    property prEndLineNum: Integer read fEndLineNum;

    property prInstrumented: boolean read fInstrumented write fInstrumented;
    property prInitial: boolean read fInitial;
    property prCmtEnterBegin: Integer read fCmtEnterBegin;
    property prCmtEnterEnd: Integer read fCmtEnterEnd;
    property prCmtExitBegin: Integer read fCmtExitBegin;
    property prCmtExitEnd: Integer read fCmtExitEnd;
    property prPureAsm: boolean read fPureAsm;


    property unSetThreadNames: TProcSetThreadNameList read fSetThreadNames;
  end;

  TProcList = class(TRootNode<TProc>)
  protected
    function GetLookupKey(const aValue : TProc) : string; override;
    function AdjustKey(const aName : string): string;
  public
    constructor Create; reintroduce;
    procedure Add(var procName: string; pureAsm: boolean;offset, lineNum, headerLineNum: Integer);
    procedure AddEnd(procName: string; offset, lineNum: Integer);
    procedure AddInstrumented(procName: string;cmtEnterBegin, cmtEnterEnd, cmtExitBegin, cmtExitEnd: Integer);
    procedure SetAllInstrumented(const aValue : Boolean);
    function FindNode(const aLookupKey : string; out aResultNode: INode<TProc>) : boolean; overload;

  end;


implementation

{ TProcSetThreadNameList }

constructor TProcSetThreadNameList.Create;
begin
  inherited Create();
end;

procedure TProcSetThreadNameList.AddPosition(const aPos: Cardinal;
  const aSelfBuffer: string);
var
  LThreadName: TProcSetThreadName;
begin
  LThreadName := TProcSetThreadName.Create();
  LThreadName.tpstnPos := aPos;
  LThreadName.tpstnWithSelf := aSelfBuffer;
  self.AppendNode(LThreadName);
end;

function TProcSetThreadNameList.GetLookupKey(const aValue: TProcSetThreadName): string;
begin
  result := aValue.tpstnPos.ToString();
end;

{ ========================= TProc ========================= }

constructor TProc.Create(procName: string;
  offset, lineNum, headerLineNum: Integer);
begin
  inherited Create();
  prName := procName;
  fHeaderLineNum := headerLineNum;
  fStartOffset := offset;
  fStartLineNum := lineNum;
  fInstrumented := False;
  fSetThreadNames := TProcSetThreadNameList.Create();
end; { TProc.Create }

destructor TProc.Destroy;
begin
  fSetThreadNames.Free;
  inherited;
end; { TProc.Destroy }

function TProc.GetName: String;
begin
  result := String(prName);
end;


{ ========================= TProcList ========================= }

function CompareProc(node1, node2: INode<TProc>): Integer;
begin
  Result := String.Compare(node1.Data.Name, node2.Data.prName,true);
end; { CompareProc }

constructor TProcList.Create;
begin
  inherited Create();
  CompareFunc := @CompareProc;
end;

function TProcList.FindNode(const aLookupKey: string; out aResultNode: INode<TProc>): boolean;
begin
  result := inherited FindNode(AdjustKey(aLookupKey), aResultNode);
end;

function TProcList.GetLookupKey(const aValue: TProc): string;
begin
  result := AdjustKey(aValue.Name);
end;

procedure TProcList.SetAllInstrumented(const aValue: Boolean);
var
  LProcEnumor: TRootNode<TProc>.TEnumerator;
begin
  LProcEnumor := GetEnumerator();
  while LProcEnumor.MoveNext do
    LProcEnumor.Current.Data.fInstrumented := aValue;
  LProcEnumor.Free;
end;

{ TProcList.Create }

procedure TProcList.Add(var procName: string; pureAsm: boolean;
  offset, lineNum, headerLineNum: Integer);
var
  post: Integer;
  overloaded: boolean;
  LSearchEntry: INode<TProc>;
  LFoundEntry: INode<TProc>;

begin
  LSearchEntry := TNode<TProc>.Create();
  LSearchEntry.Data := TProc.Create(procName, offset, lineNum, headerLineNum);
  if FindNode(LSearchEntry, LFoundEntry) then
  begin
    LFoundEntry.Data.prName := LFoundEntry.Data.prName + ':1';
    overloaded := true;
    LSearchEntry.Data.prName := procName + ':1';
  end
  else
  begin
    LSearchEntry.Data.prName := procName + ':1';
    overloaded := FindNode(LSearchEntry, LFoundEntry);
    if not overloaded then
      LSearchEntry.Data.prName := procName;
  end;
  if overloaded then
  begin // fixup for overloaded procedures
    post := 1;
    while FindNode(LSearchEntry, LFoundEntry) do
    begin
      Inc(post);
      LSearchEntry.Data.prName := procName + ':' + IntToStr(post);
    end;
    procName := LSearchEntry.Data.prName;
  end;
  with LSearchEntry.Data do
  begin
    fCmtEnterBegin := -1;
    fCmtEnterEnd := -1;
    fCmtExitBegin := -1;
    fCmtExitEnd := -1;
    fPureAsm := pureAsm;
  end;
  AppendNode(LSearchEntry.Data);

end; { TProcList.Add }

procedure TProcList.AddEnd(procName: string; offset, lineNum: Integer);
var
  LFoundEntry, LSearchEntry: INode<TProc>;
begin
  LSearchEntry := TNode<TProc>.Create();
  LSearchEntry.Data := TProc.Create(procName);
  if FindNode(LSearchEntry, LFoundEntry) then
  begin
    with LFoundEntry.Data do
    begin
      fEndOffset := offset;
      fEndLineNum := lineNum;
      fInitial := False;
    end;
  end;
end; { TProcList.AddEnd }

procedure TProcList.AddInstrumented(procName: string;
  cmtEnterBegin, cmtEnterEnd, cmtExitBegin, cmtExitEnd: Integer);
var
  LFoundEntry, LSearchEntry: INode<TProc>;
begin
  LSearchEntry := TNode<TProc>.Create();
  LSearchEntry.Data := TProc.Create(procName);
  if FindNode(LSearchEntry, LFoundEntry) then
  begin
    with LFoundEntry.Data do
    begin
      fCmtEnterBegin := cmtEnterBegin;
      fCmtEnterEnd := cmtEnterEnd;
      fCmtExitBegin := cmtExitBegin;
      fCmtExitEnd := cmtExitEnd;
      fInstrumented := true;
      fInitial := true;
    end;
  end;
end; function TProcList.AdjustKey(const aName: string): string;
begin
  result := AnsiLowerCase(aName);
end;

{ TProcList.AddInstrumented }


end.
