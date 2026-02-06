unit MU_Slider;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics;

type
  TMUSlider = class(TCustomControl)
  private
    FPosition: Integer;
    FMin: Integer;
    FMax: Integer;
    FColor_BackGround: TColor;
    FColor_Bar: TColor;
    FColor_Thumb: TColor;
    FThumbRadius: Integer;

    FCaption_Left: string;
    FCaption_Right: string;
    FCaption_Thumb: string;
    FShowCaptions: Boolean;
    FCaptionFont: TFont;
    FCaptionColor: TColor;
    procedure SetMin(Value: Integer);
    procedure SetMax(Value: Integer);
    procedure SetPosition(Value: Integer);

    procedure SetColor_Background(Value: TColor);
    procedure SetColor_Bar(Value: TColor);
    procedure SetColor_Thumb(Value: TColor);
    procedure SetBackgroundColor(const Value: TColor);
    procedure SetBarColor(const Value: TColor);
    procedure SetThumbColor(const Value: TColor);

    procedure SetCaption_Left(const Value: string);
    procedure SetCaption_Right(const Value: string);
    procedure SetCaption_Thumb(const Value: string);
    procedure SetShowCaptions(Value: Boolean);
    procedure SetCaptionFont(Value: TFont);
    procedure SetCaptionColor(Value: TColor);

    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    function GetRect_Thumb(BarY: Integer): TRect;
    function GetRect_Bar(BarY: Integer): TRect;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    // 기본 제공
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Visible;
    property TabOrder;
    property TabStop;

    // 추가
    property Position: Integer read FPosition write SetPosition;
    property Min: Integer read FMin write SetMin;
    property Max: Integer read FMax write SetMax;
    property Color_BackGround: TColor read FColor_BackGround write SetBackgroundColor;
    property Color_Bar: TColor read FColor_Bar write SetBarColor;
    property Color_Thumb: TColor read FColor_Thumb write SetThumbColor;
    property ThumbRadius: Integer read FThumbRadius write FThumbRadius;

    property Caption_Left: string read FCaption_Left write SetCaption_Left;
    property Caption_Right: string read FCaption_Right write SetCaption_Right;
    property Caption_Thumb: string read FCaption_Thumb write SetCaption_Thumb;
    property ShowCaptions: Boolean read FShowCaptions write SetShowCaptions;
    property CaptionFont: TFont read FCaptionFont write SetCaptionFont;
    property CaptionColor: TColor read FCaptionColor write SetCaptionColor;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MS_Control', [TMUSlider]);
end;

{ TMUSlider }

constructor TMUSlider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 30;
  FMin := 0;
  FMax := 100;
  FPosition := 50;
  FColor_BackGround := clBlack;
  FColor_Bar := clGray;
  FColor_Thumb := clWhite;
  FThumbRadius := 8;

  FCaption_Left := 'Min';
  FCaption_Right := 'Max';
  FCaption_Thumb := '';
  FShowCaptions := False;
  FCaptionFont := TFont.Create;
  FCaptionFont.Name := 'Tahoma';
  FCaptionFont.Size := 8;
  FCaptionColor := clWhite;

  DoubleBuffered := True;
end;

function TMUSlider.GetRect_Bar(BarY: Integer): TRect;
begin
  Result := Rect(FThumbRadius, BarY - 5, (FPosition - FMin) * (Width - 2 * FThumbRadius) div (FMax - FMin) + FThumbRadius, BarY + 5);
end;

function TMUSlider.GetRect_Thumb(BarY: Integer): TRect;
var
  ThumbX: Integer;
begin
  ThumbX := (FPosition - FMin) * (Width - 2 * FThumbRadius) div (FMax - FMin) + FThumbRadius;
  Result := Rect(ThumbX - FThumbRadius, BarY - FThumbRadius, ThumbX + FThumbRadius, BarY + FThumbRadius);
end;

procedure TMUSlider.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NewPos: Integer;
  EffectiveWidth: Integer;
begin
  EffectiveWidth := Width - 2 * FThumbRadius; // Thumb이 움직일 수 있는 실제 영역
  NewPos := ((X - FThumbRadius) * (FMax - FMin)) div EffectiveWidth + FMin;
  SetPosition(NewPos);
end;

procedure TMUSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewPos: Integer;
  EffectiveWidth: Integer;
begin
  inherited;
  if ssLeft in Shift then
  begin
    EffectiveWidth := Width - 2 * FThumbRadius;
    NewPos := ((X - FThumbRadius) * (FMax - FMin)) div EffectiveWidth + FMin;
    SetPosition(NewPos);
  end;
end;

procedure TMUSlider.Paint;
var
  ThumbRect, BarRect: TRect;
  ThumbX, BarY: Integer;
begin
  // 배경
  Canvas.Brush.Color := FColor_BackGround;
  Canvas.RoundRect(ClientRect.Left, ClientRect.Top, ClientRect.Right, ClientRect.Bottom, 15, 15); // 마지막 두 인자가 둥근 정도(Width, Height)

  if FShowCaptions then
    BarY := Height div 2 - 10
  else
    BarY := Height div 2;

  // 진행 바
  BarRect := GetRect_Bar(BarY);
  Canvas.Brush.Color := FColor_Bar;
  Canvas.FillRect(BarRect);
  {
    Canvas.Brush.Color := FColor_Bar;
    Canvas.FillRect(Rect(FThumbRadius, Height div 2 - 5, (FPosition - FMin) * (Width - 2 * FThumbRadius) div (FMax - FMin) + FThumbRadius,
    Height div 2 + 5));
  }

  // Thumb 위치
  ThumbRect := GetRect_Thumb(BarY);
  Canvas.Brush.Color := FColor_Thumb;
  Canvas.Ellipse(ThumbRect);

  {
    ThumbX := (FPosition - FMin) * (Width - 2 * FThumbRadius) div (FMax - FMin) + FThumbRadius;
    Canvas.Brush.Color := FColor_Thumb;
    Canvas.Ellipse(ThumbX - FThumbRadius, Height div 2 - FThumbRadius, ThumbX + FThumbRadius, Height div 2 + FThumbRadius);
  }
  // 캡션 표시
  if FShowCaptions then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Assign(FCaptionFont);
    Canvas.Font.Color := FCaptionColor;

    // Left Caption
    if FCaption_Left <> '' then
      Canvas.TextOut(FThumbRadius, ThumbRect.Bottom + 2, FCaption_Left);

    // Right Caption
    if FCaption_Right <> '' then
      Canvas.TextOut(Width - Canvas.TextWidth(FCaption_Right) - FThumbRadius, ThumbRect.Bottom + 2, FCaption_Right);

    // Thumb Caption
    if FCaption_Thumb <> '' then
      Canvas.TextOut(ThumbRect.Left + (ThumbRect.Width div 2) - (Canvas.TextWidth(FCaption_Thumb) div 2), ThumbRect.Bottom + 2,
        FCaption_Thumb);
  end;
end;

procedure TMUSlider.SetBackgroundColor(const Value: TColor);
begin
  FColor_BackGround := Value;
end;

procedure TMUSlider.SetBarColor(const Value: TColor);
begin
  FColor_Bar := Value;
end;

procedure TMUSlider.SetCaptionColor(Value: TColor);
begin
  FCaptionColor := Value;
  Invalidate;
end;

procedure TMUSlider.SetCaptionFont(Value: TFont);
begin
  FCaptionFont := Value;
  Invalidate;
end;

procedure TMUSlider.SetCaption_Left(const Value: string);
begin
  FCaption_Left := Value;
  Invalidate;

end;

procedure TMUSlider.SetCaption_Right(const Value: string);
begin

  FCaption_Right := Value;
  Invalidate;
end;

procedure TMUSlider.SetCaption_Thumb(const Value: string);
begin

  FCaption_Thumb := Value;
  Invalidate;
end;

procedure TMUSlider.SetColor_Background(Value: TColor);
begin
  if FColor_BackGround <> Value then
  begin
    FColor_BackGround := Value;
    Invalidate;
  end;
end;

procedure TMUSlider.SetColor_Bar(Value: TColor);
begin
  if FColor_Bar <> Value then
  begin
    FColor_Bar := Value;
    Invalidate;
  end;
end;

procedure TMUSlider.SetColor_Thumb(Value: TColor);
begin
  if FColor_Thumb <> Value then
  begin
    FColor_Thumb := Value;
    Invalidate;
  end;
end;

procedure TMUSlider.SetMax(Value: Integer);
begin
  if Value <> FMax then
  begin
    FMax := Value; // Max가 바뀌면 Position이 최대값보다 크지 않도록 보정
    if FPosition > FMax then
      FPosition := FMax;
    Invalidate; // 다시 그리기
  end;

end;

procedure TMUSlider.SetMin(Value: Integer);
begin
  if Value <> FMin then
  begin
    FMin := Value; // Min이 바뀌면 Position이 최소값보다 작지 않도록 보정
    if FPosition < FMin then
      FPosition := FMin;
    Invalidate; // 다시 그리기
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

procedure TMUSlider.SetShowCaptions(Value: Boolean);
begin
  FShowCaptions := Value;
  Invalidate;
end;

procedure TMUSlider.SetThumbColor(const Value: TColor);
begin
  FColor_Thumb := Value;
end;

procedure TMUSlider.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin

end;

end.
