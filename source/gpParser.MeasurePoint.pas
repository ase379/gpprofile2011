unit gpParser.MeasurePoint;

interface

uses gppTree;

const
  ENTER_MP_FUNCTION_NAME = AnsiString('ProfilerEnterMP');
  EXIT_MP_FUNCTION_NAME = AnsiString('ProfilerExitMP');
  MAX_MP_NAME_LEN = 4096;
type
  TMPScanState = (undefined, ScanEnterBegin, ScanEnterEnd, ScanLeaveBegin, ScanLeaveEnd);
  // forward declaration
  TMeasurePoint = class;

  /// <summary>
  /// A tree with measure points.
  /// </summary>
  TMeasurePointList = TRootNode<TMeasurePoint>;

  /// <summary>
  /// A measure point in a proc (defined by the user)
  /// </summary>
  TMeasurePoint = class
  private
    fFileContents : PAnsiChar;
    fEnterPosBegin : Int64;
    fEnterPosEnd : Int64;
    fLeavePosBegin : Int64;
    fLeavePosEnd : Int64;

    fEnterSnippet : AnsiString;
    fLeaveSnippet : AnsiString;
    fMeasurePointName : string;
    function ExtractMpName(const aTerm, aFunctionName : ansistring): string;
    procedure RaiseError(const aContext: string);
  public
    constructor Create(const aFileBuffer: PAnsiChar);
    /// <summary>
    /// The position where the enter token begins
    /// </summary>
    property EnterPosBegin: Int64 read fEnterPosBegin write fEnterPosBegin;
    /// <summary>
    /// The position where the enter token ends
    /// </summary>
    property EnterPosEnd: Int64 read fEnterPosEnd write fEnterPosEnd;
    /// <summary>
    /// The position where the leave token begins
    /// </summary>
    property LeavePosBegin: Int64 read fLeavePosBegin write fLeavePosBegin;
    /// <summary>
    /// The position where the leave token ends
    /// </summary>
    property LeavePosEnd: Int64 read fLeavePosEnd write fLeavePosEnd;

    property Name : string read fMeasurePointName;
    /// <summary>
    /// Extracts the buffer information from the given external buffer.
    /// </summary>
    procedure ExtractSnippets();
  end;

implementation

uses
  System.Classes,System.SysUtils, System.Ansistrings;


{ TMeasurePoint }

constructor TMeasurePoint.Create(const aFileBuffer: PAnsiChar);
begin
  inherited Create();
  fFileContents := aFileBuffer;
end;

function TMeasurePoint.ExtractMpName(const aTerm, aFunctionName : ansistring): string;
var
  LTempBuffer : ansistring;
  LFuncNamePos : integer;
begin
  LFuncNamePos := System.AnsiStrings.PosEx(aFunctionName, aTerm);
  LTempBuffer := Copy(aTerm, LFuncNamePos+Length(aFunctionName),MAX_MP_NAME_LEN);
  LTempBuffer := Trim(LTempBuffer);
  if not StartsStr('(', LTempBuffer) then
    RaiseError('"(" not found after "'+aFunctionName+'".');
  Delete(LTempBuffer,1,1); // eat "("
  if not StartsStr('''', LTempBuffer) then
    RaiseError('Beginning "''" not found in "'+aFunctionName+'" call.');
  Delete(LTempBuffer,1,1); // eat "'"
  LFuncNamePos := System.AnsiStrings.PosEx('''', LTempBuffer);
  if LFuncNamePos = -1 then
    RaiseError('Ending "''" not found in "'+aFunctionName+'" call.');
  result := UTF8ToUnicodeString(Copy(LTempBuffer, 1,LFuncNamePos-1));
end;



procedure TMeasurePoint.ExtractSnippets();
var
  LMPExitName : string;
begin
  fEnterSnippet := Copy(fFileContents,EnterPosBegin+1,EnterPosEnd-EnterPosBegin);
  fLeaveSnippet := Copy(fFileContents,LeavePosBegin+1,LeavePosEnd-LeavePosBegin);
  if not ContainsStr(fEnterSnippet, ENTER_MP_FUNCTION_NAME) then
    RaiseError(ENTER_MP_FUNCTION_NAME+ ' not found in Measure Point enter define.');
  fMeasurePointName := ExtractMpName(fEnterSnippet, ENTER_MP_FUNCTION_NAME);
  LMPExitName := ExtractMpName(fLeaveSnippet, EXIT_MP_FUNCTION_NAME);
  if not SameText(fMeasurePointName, LMPExitName) then
    RaiseError(ENTER_MP_FUNCTION_NAME+' uses name "'+fMeasurePointName+'", but '+EXIT_MP_FUNCTION_NAME+' uses name "'+LMPExitName+'".');
end;

procedure TMeasurePoint.RaiseError(const aContext: string);
begin
  raise EParserError.Create(aContext);
end;

end.
