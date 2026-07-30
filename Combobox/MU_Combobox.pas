unit MU_Combobox;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, Math,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.StdCtrls, Winapi.Messages;

type
  TMUCombobox = class(TCustomControl)
  private
    FFont: TFont;
    FFontDrop: TColor;
    FItems: TStrings;
    FItemIndex: Integer;
    FItemHeight: Integer;
    FColor: TColor;
    FColorDropDown: TColor;
    FColorHover: TColor;
    FPopupForm: TForm;
    FPopupList: TListBox;
    FDropDownCount: Integer;
    FOnChange: TNotifyEvent;

    procedure SetItems(Value: TStrings);
    procedure SetItemIndex(Value: Integer);
    procedure SetItemHeight(Value: Integer);
    procedure SetDropDownCount(Value: Integer);
    procedure SetColorDropDown(Value: TColor);
    procedure SetColorHover(Value: TColor);
    procedure DoChange;
    procedure PopupFormDeactivate(Sender: TObject);
    procedure PopupListSelect(Sender: TObject);
    procedure ShowDropDown;

    procedure SetFFont(Value: TFont);
    procedure FFontChanged(Sender: TObject);

    function CalcDropDownItemHeight: Integer;
    function CalcDropDownWidth: Integer;

    procedure FreePopup;
    procedure WmFreePopup(var Msg: TMessage); message WM_USER + 1;
  protected
    procedure DestroyWnd; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Font;
    property ParentFont;
    property Items: TStrings read FItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property ItemHeight: Integer read FItemHeight write SetItemHeight;
    property Color: TColor read FColor write FColor;
    property ColorDropDown: TColor read FColorDropDown write SetColorDropDown;
    property ColorHover: TColor read FColorHover write SetColorHover;
    property DropDownCount: Integer read FDropDownCount write SetDropDownCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property DropDownFont: TFont read FFont write SetFFont;
    property FontDropColor: TColor read FFontDrop write FFontDrop;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MU_Control', [TMUCombobox]);
end;

{ TMUCombobox }

procedure TMUCombobox.FreePopup;
var
  PopupForm: TForm;
  PopupList: TListBox;
begin
  // 해제 중 Notification이 재진입해도 같은 객체를 다시 참조하지 않게
  // 필드를 가장 먼저 비운다.
  PopupForm := FPopupForm;
  PopupList := FPopupList;
  FPopupForm := nil;
  FPopupList := nil;

  if Assigned(PopupList) then
    PopupList.OnClick := nil;

  if Assigned(PopupForm) then
  begin
    // 메인 폼 종료 중 포커스를 이미 파괴된 PopupParent로 돌려보내지 않는다.
    PopupForm.OnDeactivate := nil;
    PopupForm.PopupParent := nil;
    PopupForm.PopupMode := pmNone;
    if PopupForm.HandleAllocated then
      ShowWindow(PopupForm.Handle, SW_HIDE);
    PopupForm.Free; // PopupList도 PopupForm이 소유하므로 함께 해제된다.
  end
  else
    PopupList.Free;
end;

procedure TMUCombobox.DestroyWnd;
begin
  // 부모 폼이 먼저 윈도우 핸들을 없애기 전에 팝업을 닫는다.
  FreePopup;
  inherited DestroyWnd;
end;

function TMUCombobox.CalcDropDownItemHeight: Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FFont);
    Result := Max(FItemHeight, Bmp.Canvas.TextHeight('Hg') + 8);
  finally
    Bmp.Free;
  end;
end;

function TMUCombobox.CalcDropDownWidth: Integer;
var
  Bmp: TBitmap;
  I, W: Integer;
begin
  Result := Width;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FFont);

    for I := 0 to FItems.Count - 1 do
    begin
      W := Bmp.Canvas.TextWidth(FItems[I]) + 20;
      if W > Result then
        Result := W;
    end;
  finally
    Bmp.Free;
  end;

  if FItems.Count > FDropDownCount then
    Inc(Result, GetSystemMetrics(SM_CXVSCROLL));
end;

procedure TMUCombobox.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

constructor TMUCombobox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;

  FFont := TFont.Create;
  FFont.Assign(Self.Font);
  FFont.OnChange := FFontChanged;

  FItemIndex := -1;
  FColor := clWindow;
  FColorDropDown := clWhite;
  FColorHover := clHighlight;
  FFontDrop := clBlack;
  FItemHeight := 20;
  FDropDownCount := 8;

  Width := 120;
  Height := 24;
end;

destructor TMUCombobox.Destroy;
begin
  // Destroy 중에는 곧 사라질 Self.Handle로 메시지를 보내면 안 된다.
  FreePopup;

  FreeAndNil(FFont);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TMUCombobox.Paint;
var
  TextRect: TRect;
  ArrowRect: TRect;
  Flags: Integer;
begin
  Canvas.Brush.Color := FColor;
  Canvas.FillRect(ClientRect);

  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Color := Self.Font.Color;

  TextRect := Rect(4, 0, Width - 24, Height);
  ArrowRect := Rect(Width - 24, 0, Width, Height);

  Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;

  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    DrawText(Canvas.Handle, PChar(FItems[FItemIndex]), -1, TextRect, Flags);

  // 드롭다운 버튼 영역
  Canvas.Brush.Color := FColor;
  Canvas.FillRect(ArrowRect);

  DrawText(Canvas.Handle, PChar('▼'), -1, ArrowRect, DT_SINGLELINE or DT_VCENTER or DT_CENTER);
end;

procedure TMUCombobox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    if Assigned(FPopupList) then
      PostMessage(Self.Handle, WM_USER + 1, 0, 0)
    else
      ShowDropDown;
  end;
end;

procedure TMUCombobox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
  begin
    if AComponent = FPopupForm then
    begin
      FPopupForm := nil;
      FPopupList := nil;
    end
    else if AComponent = FPopupList then
      FPopupList := nil
    else if AComponent = Parent then
      FreePopup;
  end;
  inherited Notification(AComponent, Operation);
end;

procedure TMUCombobox.SetItems(Value: TStrings);
begin
  FItems.Assign(Value);
  FItemIndex := -1;
  Invalidate;
end;

procedure TMUCombobox.SetItemIndex(Value: Integer);
begin
  if (Value >= 0) and (Value < FItems.Count) then
  begin
    FItemIndex := Value;
    Invalidate;
    DoChange;
  end;
end;

procedure TMUCombobox.SetItemHeight(Value: Integer);
begin
  if Value > 0 then
  begin
    FItemHeight := Value;
    Invalidate;
  end;
end;

procedure TMUCombobox.SetColorDropDown(Value: TColor);
begin
  if FColorDropDown = Value then
    Exit;
  FColorDropDown := Value;

  // 팝업이 떠 있으면 즉시 반영
  if Assigned(FPopupList) then
  begin
    // 부모 색상 상속을 방지
{$IFDEF HAS_PARENTCOLOR}
    FPopupList.ParentColor := False;
{$ENDIF}
    FPopupList.Color := FColorDropDown;

    // owner-draw가 아닌 경우 기본 배경 색을 즉시 갱신
    FPopupList.Invalidate;
    FPopupList.Refresh;
  end;

  // 메인 컨트롤 다시 그리기
  Invalidate;
end;

procedure TMUCombobox.SetColorHover(Value: TColor);
begin
  if FColorHover = Value then
    Exit;
  FColorHover := Value;

  // Hover 색상은 보통 owner-draw나 MouseMove에서 사용하므로
  // 팝업이 떠있다면 팝업을 다시 그리게 함
  if Assigned(FPopupList) then
  begin
    // 기본 리스트박스는 Hover 상태를 자체적으로 그리지 않으므로
    // owner-draw로 구현한 경우에는 Invalidate 호출로 반영
    FPopupList.Invalidate;
  end;
end;

procedure TMUCombobox.SetDropDownCount(Value: Integer);
begin
  if Value > 0 then
    FDropDownCount := Value
  else
    FDropDownCount := 1;
end;

procedure TMUCombobox.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TMUCombobox.PopupFormDeactivate(Sender: TObject);
begin
  // OnDeactivate 이벤트 안에서 팝업 폼 자신을 바로 Free하지 않는다.
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_USER + 1, 0, 0);
end;

procedure TMUCombobox.SetFFont(Value: TFont);
begin
  FFont.Assign(Value);
  FFont.OnChange := FFontChanged;

  if Assigned(FPopupList) then
  begin
    FPopupList.Font.Assign(FFont);
    FPopupList.Font.Color := FFontDrop;
  end;
end;

procedure TMUCombobox.FFontChanged(Sender: TObject);
begin
  // 디자인타임/런타임에서 FFont가 변경되면 팝업에 반영
  if Assigned(FPopupList) then
    FPopupList.Font.Assign(FFont);
end;

procedure TMUCombobox.PopupListSelect(Sender: TObject);
begin
  if Assigned(FPopupList) then
  begin
    FItemIndex := FPopupList.ItemIndex;
    if FItemIndex >= 0 then
    begin
      Invalidate;
      DoChange;
    end;
    PostMessage(Self.Handle, WM_USER + 1, 0, 0);
  end;
end;

procedure TMUCombobox.ShowDropDown;
var
  VisibleCount: Integer;
  RowHeight: Integer;
  PopupWidth, PopupHeight: Integer;
  PopupPoint, ComboPoint: TPoint;
  WorkArea: TRect;
  Monitor: TMonitor;
begin
  if (csDesigning in ComponentState) then
    Exit;
  if FItems.Count = 0 then
    Exit;
  if Parent = nil then
    Exit;

  RowHeight := CalcDropDownItemHeight;
  VisibleCount := Min(FItems.Count, FDropDownCount);
  PopupWidth := CalcDropDownWidth;
  PopupHeight := VisibleCount * RowHeight + 4;

  // Panel이나 메인 폼의 영역에 잘리지 않도록 독립 팝업 폼을 사용한다.
  PopupPoint := ClientToScreen(Point(0, Height));
  ComboPoint := ClientToScreen(Point(0, 0));
  Monitor := Screen.MonitorFromPoint(PopupPoint, mdNearest);
  WorkArea := Monitor.WorkareaRect;

  if PopupPoint.Y + PopupHeight > WorkArea.Bottom then
    PopupPoint.Y := ComboPoint.Y - PopupHeight;
  if PopupPoint.X + PopupWidth > WorkArea.Right then
    PopupPoint.X := WorkArea.Right - PopupWidth;
  if PopupPoint.X < WorkArea.Left then
    PopupPoint.X := WorkArea.Left;
  if PopupPoint.Y < WorkArea.Top then
    PopupPoint.Y := WorkArea.Top;

  // Owner를 Self로 지정하면 종료 중 Self.Handle을 다시 요구할 수 있으므로
  // 소유자는 nil로 두고 FreePopup에서 수명을 명시적으로 관리한다.
  FPopupForm := TForm.CreateNew(nil);
  FPopupForm.FreeNotification(Self);
  FPopupForm.BorderStyle := bsNone;
  FPopupForm.Position := poDesigned;
  FPopupForm.PopupMode := pmExplicit;
  FPopupForm.PopupParent := GetParentForm(Self);
  FPopupForm.OnDeactivate := PopupFormDeactivate;
  FPopupForm.SetBounds(PopupPoint.X, PopupPoint.Y, PopupWidth, PopupHeight);

  FPopupList := TListBox.Create(FPopupForm);
  FPopupList.FreeNotification(Self);
  FPopupList.Parent := FPopupForm;
  FPopupList.Align := alClient;
  FPopupList.IntegralHeight := False;

  FPopupList.Font.Assign(FFont);
  FPopupList.Font.Color := FFontDrop;
  FPopupList.Color := FColorDropDown;

  FPopupList.ItemHeight := RowHeight;
  FPopupList.Perform(LB_SETITEMHEIGHT, 0, RowHeight);

  FPopupList.Items.Assign(FItems);
  FPopupList.ItemIndex := FItemIndex;
  FPopupList.OnClick := PopupListSelect;

  FPopupForm.Show;
  FPopupList.SetFocus;
end;

procedure TMUCombobox.WmFreePopup(var Msg: TMessage);
begin
  FreePopup;
end;

end.
