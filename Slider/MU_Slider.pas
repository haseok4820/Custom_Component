unit MU_Slider;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Graphics;

type
  TMUSlider = class(TCustomControl)
  private
    // 기본 슬라이더 속성
    FPosition: Integer;
    FMin: Integer;
    FMax: Integer;
    FThumbRadius: Integer;
    FColor_Background: TColor;
    FColor_Bar: TColor;
    FColor_Thumb: TColor;

    // Caption 관련 속성
    FCaption_Left: string;
    FCaption_Right: string;
    FCaption_Thumb: string;
    FCaption_Show: Boolean;
    FCaption_Font: TFont;
    FCaption_Color: TColor;

    // 내부 메서드
    procedure SetPosition(Value: Integer);
    procedure UpdateCaption(var Field: string; const Value: string);
    function GetThumbX: Integer;
    function GetThumbRect(BarY: Integer): TRect;
    function GetBarRect(BarY: Integer): TRect;
    procedure DrawCaption(const AText: string; X, Y: Integer);

    // Setter
    procedure SetMin(Value: Integer);
    procedure SetMax(Value: Integer);
    procedure SetColor_Background(Value: TColor);
    procedure SetColor_Bar(Value: TColor);
    procedure SetColor_Thumb(Value: TColor);
    procedure SetCaption_Left(const Value: string);
    procedure SetCaption_Right(const Value: string);
    procedure SetCaption_Thumb(const Value: string);
    procedure SetCaption_Show(Value: Boolean);
    procedure SetCaption_Font(Value: TFont);
    procedure SetCaption_Color(Value: TColor);

    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;

    // Event
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Caption 일괄 처리 메서드
    procedure SetCaptions(const ALeft, ARight, AThumb: string; AShow: Boolean = True);

  published
    // 기본 레이아웃 속성
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property TabOrder;
    property TabStop;

    // 슬라이더 속성
    property Position: Integer read FPosition write SetPosition;
    property Min: Integer read FMin write SetMin;
    property Max: Integer read FMax write SetMax;
    property ThumbRadius: Integer read FThumbRadius write FThumbRadius;
    property BackgroundColor: TColor read FColor_Background write SetColor_Background;
    property BarColor: TColor read FColor_Bar write SetColor_Bar;
    property ThumbColor: TColor read FColor_Thumb write SetColor_Thumb;

    // Caption 속성
    property Caption_Left: string read FCaption_Left write SetCaption_Left;
    property Caption_Right: string read FCaption_Right write SetCaption_Right;
    property Caption_Thumb: string read FCaption_Thumb write SetCaption_Thumb;
    property Caption_Show: Boolean read FCaption_Show write SetCaption_Show;
    property Caption_Font: TFont read FCaption_Font write SetCaption_Font;
    property Caption_Color: TColor read FCaption_Color write SetCaption_Color;

    // Events
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MU_Control', [TMUSlider]);
end;

{ TMUSlider }

constructor TMUSlider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 50;
  FMin := 0;
  FMax := 100;
  FPosition := 50;
  FThumbRadius := 8;
  FColor_Background := $00440000;
  FColor_Bar := $009A5210;
  FColor_Thumb := clWhite;

  FCaption_Left := 'Min';
  FCaption_Right := 'Max';
  FCaption_Thumb := '';
  FCaption_Show := True;

  FCaption_Font := TFont.Create;
  FCaption_Font.Name := 'Tahoma';
  FCaption_Font.Size := 8;
  FCaption_Color := clWhite;

  DoubleBuffered := True;
end;

destructor TMUSlider.Destroy;
begin
  FCaption_Font.Free;
  inherited;
end;

procedure TMUSlider.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

function TMUSlider.GetThumbX: Integer;
begin
  Result := (FPosition - FMin) * (Width - 2 * FThumbRadius) div (FMax - FMin) + FThumbRadius;
end;

function TMUSlider.GetThumbRect(BarY: Integer): TRect;
var
  ThumbX: Integer;
begin
  ThumbX := GetThumbX;
  Result := Rect(ThumbX - FThumbRadius, BarY - FThumbRadius, ThumbX + FThumbRadius, BarY + FThumbRadius);
end;

function TMUSlider.GetBarRect(BarY: Integer): TRect;
begin
  Result := Rect(FThumbRadius, BarY - 5, GetThumbX, BarY + 5);
end;

procedure TMUSlider.UpdateCaption(var Field: string; const Value: string);
begin
  if Field <> Value then
  begin
    Field := Value;
    Invalidate;
  end;
end;

procedure TMUSlider.SetPosition(Value: Integer);
begin
  if Value < FMin then
    Value := FMin;
  if Value > FMax then
    Value := FMax;
  if FPosition <> Value then
  begin
    FPosition := Value;
    Invalidate;
  end;
end;

procedure TMUSlider.SetMin(Value: Integer);
begin
  FMin := Value;
  if FPosition < FMin then
    FPosition := FMin;
  Invalidate;
end;

procedure TMUSlider.SetMax(Value: Integer);
begin
  FMax := Value;
  if FPosition > FMax then
    FPosition := FMax;
  Invalidate;
end;

procedure TMUSlider.SetColor_Background(Value: TColor);
begin
  FColor_Background := Value;
  Invalidate;
end;

procedure TMUSlider.SetColor_Bar(Value: TColor);
begin
  FColor_Bar := Value;
  Invalidate;
end;

procedure TMUSlider.SetColor_Thumb(Value: TColor);
begin
  FColor_Thumb := Value;
  Invalidate;
end;

procedure TMUSlider.SetCaption_Left(const Value: string);
begin
  UpdateCaption(FCaption_Left, Value);
end;

procedure TMUSlider.SetCaption_Right(const Value: string);
begin
  UpdateCaption(FCaption_Right, Value);
end;

procedure TMUSlider.SetCaption_Thumb(const Value: string);
begin
  UpdateCaption(FCaption_Thumb, Value);
end;

procedure TMUSlider.SetCaption_Show(Value: Boolean);
begin
  if FCaption_Show <> Value then
  begin
    FCaption_Show := Value;
    Invalidate;
  end;
end;

procedure TMUSlider.SetCaption_Font(Value: TFont);
begin
  FCaption_Font.Assign(Value);
  Invalidate;
end;

procedure TMUSlider.SetCaption_Color(Value: TColor);
begin
  FCaption_Color := Value;
  Invalidate;
end;

procedure TMUSlider.SetCaptions(const ALeft, ARight, AThumb: string; AShow: Boolean);
begin
  FCaption_Left := ALeft;
  FCaption_Right := ARight;
  FCaption_Thumb := AThumb;
  FCaption_Show := AShow;
  Invalidate;
end;

procedure TMUSlider.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NewPos, EffectiveWidth: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  EffectiveWidth := Width - 2 * FThumbRadius;
  NewPos := ((X - FThumbRadius) * (FMax - FMin)) div EffectiveWidth + FMin;
  SetPosition(NewPos);
end;

procedure TMUSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewPos, EffectiveWidth: Integer;
begin
  if ssLeft in Shift then
  begin
    EffectiveWidth := Width - 2 * FThumbRadius;
    NewPos := ((X - FThumbRadius) * (FMax - FMin)) div EffectiveWidth + FMin;
    SetPosition(NewPos);
  end;
end;

procedure TMUSlider.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TMUSlider.DrawCaption(const AText: string; X, Y: Integer);
begin
  if AText = '' then
    Exit;
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(FCaption_Font);
  Canvas.Font.Color := FCaption_Color;
  Canvas.TextOut(X, Y, AText);
end;

procedure TMUSlider.Paint;
var
  ThumbRect, BarRect: TRect;
  ThumbX, BarY: Integer;
begin
  // 배경
  Canvas.Brush.Color := FColor_Background;
  Canvas.RoundRect(ClientRect.Left, ClientRect.Top, ClientRect.Right, ClientRect.Bottom, 15, 15);

  if FCaption_Show then
    BarY := Height div 2 - 10
  else
    BarY := Height div 2;

  // 진행 바
  BarRect := GetBarRect(BarY);
  Canvas.Brush.Color := FColor_Bar;
  Canvas.RoundRect(BarRect.Left, BarRect.Top, BarRect.Right, BarRect.Bottom, 10, 10);

  // Thumb
  ThumbRect := GetThumbRect(BarY);
  Canvas.Brush.Color := FColor_Thumb;
  Canvas.Ellipse(ThumbRect);

  // 캡션 표시
  if FCaption_Show then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Assign(FCaption_Font);
    Canvas.Font.Color := FCaption_Color;

    // Left Caption
    DrawCaption(FCaption_Left, FThumbRadius, ThumbRect.Bottom + 2);

    // Right Caption
    DrawCaption(FCaption_Right, Width - Canvas.TextWidth(FCaption_Right) - FThumbRadius, ThumbRect.Bottom + 2);

    // Thumb Caption
    DrawCaption(FCaption_Thumb, ThumbRect.Left + (ThumbRect.Width div 2) - (Canvas.TextWidth(FCaption_Thumb) div 2), ThumbRect.Bottom + 2);
  end;
end;

end.
