unit testThreads;

interface

uses
  System.Classes;

type
  TTestThread = class(TThread)
  public
    constructor Create();
  protected
    procedure Execute; override;

  end;

implementation

uses GpProf;

{ TTestThread }

constructor TTestThread.Create;
begin
  inherited Create();
end;

procedure TTestThread.Execute;
begin
  NameThreadForDebugging('AwesomeThread', self.ThreadID);
  self.namethreadfordebugging('AwesomeThread2☺☼d156exÈ', self.ThreadID);
  {>>GpProfile MP Enter} ProfilerEnterMP('TEST'); try {GpProfile MP Enter>>}
  Sleep(1000);
  {>>GpProfile MP Leave} finally ProfilerExitMP('TEST'); end; {GpProfile MP Leave>>}
  inherited;
end;

end.
