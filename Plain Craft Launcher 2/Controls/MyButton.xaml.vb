Imports System.Windows.Markup

<ContentProperty("Inlines")>
Public Class MyButton

    '声明
    Public Event Click(sender As Object, e As MouseButtonEventArgs) '自定义事件

    '自定义属性
    Public Uuid As Integer = GetUuid()
    Public ReadOnly Property Inlines As InlineCollection
        Get
            Return LabText.Inlines
        End Get
    End Property
    Public Property Text As String
        Get
            Return GetValue(TextProperty)
        End Get
        Set(value As String)
            SetValue(TextProperty, value)
        End Set
    End Property '显示文本
    Public Shared ReadOnly TextProperty As DependencyProperty = DependencyProperty.Register("Text", GetType(String), GetType(MyButton), New PropertyMetadata(New PropertyChangedCallback(
    Sub(sender As DependencyObject, e As DependencyPropertyChangedEventArgs)
        If sender IsNot Nothing Then CType(sender, MyButton).LabText.Text = e.NewValue
    End Sub)))
    Public Property TextPadding As Thickness
        Get
            Return LabText.Padding
        End Get
        Set(value As Thickness)
            LabText.Padding = value
        End Set
    End Property
    Private _ColorType As ColorState = ColorState.Normal  '配色方案
    Public Property ColorType As ColorState
        Get
            Return _ColorType
        End Get
        Set(value As ColorState)
            _ColorType = value
            RefreshColor()
        End Set
    End Property
    Public Enum ColorState
        Normal = 0
        Highlight = 1
        Red = 2
    End Enum
    '属性穿透
    Public Shared Shadows ReadOnly PaddingProperty As DependencyProperty = DependencyProperty.Register("Padding", GetType(Thickness), GetType(MyButton), New PropertyMetadata(New PropertyChangedCallback(
        Sub(sender As MyButton, e As DependencyPropertyChangedEventArgs) If sender IsNot Nothing Then sender.PanTextHost.Padding = e.NewValue)))
    Public Overloads Property Padding As Thickness
        Get
            Return PanTextHost.Padding
        End Get
        Set(value As Thickness)
            PanTextHost.Padding = value
        End Set
    End Property
    Public Property RealRenderTransform As Transform
        Get
            Return PanFore.RenderTransform
        End Get
        Set(value As Transform)
            PanFore.RenderTransform = value
        End Set
    End Property

    '自定义事件
    Private Const AnimationColorIn As Integer = 100
    Private Const AnimationColorOut As Integer = 200
    Private Sub RefreshColor(Optional obj = Nothing, Optional e = Nothing) Handles Me.MouseEnter, Me.MouseLeave, Me.Loaded, Me.IsEnabledChanged
        Try
            '配色：边框 / 背景 / 文字
            Dim BorderRes As String
            Dim BackRes As String
            Dim TextRes As String
            Select Case If(IsEnabled, ColorType, CType(-1, ColorState))
                Case ColorState.Normal
                    BorderRes = If(IsMouseOver, "ColorBrush5", "ColorBrushSoftBorder")
                    BackRes = If(IsMouseOver, "ColorBrushHoverFill", "ColorBrushSurface")
                    TextRes = If(IsMouseOver, "ColorBrush2", "ColorBrush1")
                Case ColorState.Highlight
                    '主按钮：实心强调色，悬停时提亮
                    BorderRes = If(IsMouseOver, "ColorBrush4", "ColorBrush3")
                    BackRes = If(IsMouseOver, "ColorBrush4", "ColorBrush3")
                    TextRes = "ColorBrushOnAccent"
                Case ColorState.Red
                    BorderRes = If(IsMouseOver, "ColorBrushRedLight", "ColorBrushRedBorder")
                    BackRes = If(IsMouseOver, "ColorBrushRedBack", "ColorBrushSurface")
                    TextRes = "ColorBrushRedDark"
                Case Else
                    '不可用
                    BorderRes = "ColorBrushGray6"
                    BackRes = "ColorBrushGray7"
                    TextRes = "ColorBrushGray4"
            End Select
            PanShine.Opacity = If(IsEnabled AndAlso ColorType = ColorState.Highlight, 0.9, 0)
            AniResColor(PanFore, Border.BorderBrushProperty, BorderRes, "MyButton Border " & Uuid, If(IsMouseOver, AnimationColorIn, AnimationColorOut))
            AniResColor(PanFore, BackgroundProperty, BackRes, "MyButton Background " & Uuid, If(IsMouseOver, AnimationColorIn, AnimationColorOut))
            AniResColor(LabText, TextBlock.ForegroundProperty, TextRes, "MyButton Text " & Uuid, If(IsMouseOver, AnimationColorIn, AnimationColorOut))
        Catch ex As Exception
            Logger.Warn(ex, "刷新按钮颜色出错")
        End Try
    End Sub
    ''' <summary>
    ''' 将该控件的某个颜色属性动画到指定资源；不支持动画时直接应用资源。
    ''' </summary>
    Private Sub AniResColor(Obj As FrameworkElement, Prop As DependencyProperty, Res As String, Key As String, Time As Integer)
        AniStop(Key)
        If IsLoaded AndAlso AniControlEnabled = 0 Then
            AniStart({AaColor(Obj, Prop, Res, Time)}, Key)
        Else
            Obj.SetResourceReference(Prop, Res)
        End If
    End Sub

    '鼠标点击判定（务必放在点击事件之后，以使得 Button_MouseUp 先于 Button_MouseLeave 执行）
    Private IsMouseDown As Boolean = False
    Private Sub Button_MouseUp(sender As Object, e As MouseButtonEventArgs) Handles Me.MouseLeftButtonUp
        If Not IsMouseDown Then Return
        Logger.Info($"按下按钮：{Text}")
        RaiseEvent Click(sender, e)
        RaiseCustomEvent() '自定义事件
    End Sub
    Private Sub Button_MouseDown(sender As Object, e As MouseButtonEventArgs) Handles Me.MouseLeftButtonDown
        IsMouseDown = True
        Focus()
        AniStart({
                 AaScaleTransform(PanFore, 0.955 - CType(PanFore.RenderTransform, ScaleTransform).ScaleX, 80,, New AniEaseOutFluent(AniEasePower.ExtraStrong)),
                 AaScaleTransform(PanFore, -0.01, 700,, New AniEaseOutFluent(AniEasePower.Middle))
                 }, "MyButton Scale " & Uuid)
    End Sub
    Private Sub Button_MouseUp() Handles Me.MouseLeftButtonUp
        If Not IsMouseDown Then Return
        IsMouseDown = False
        AniStart({
               AaScaleTransform(PanFore, 1 - CType(PanFore.RenderTransform, ScaleTransform).ScaleX, 300, 10, New AniEaseOutFluent(AniEasePower.Middle))
           }, "MyButton Scale " & Uuid)
    End Sub
    Private Sub Button_MouseLeave() Handles Me.MouseLeave
        If Not IsMouseDown Then Return
        IsMouseDown = False
        AniStart(AaScaleTransform(PanFore, 1 - CType(PanFore.RenderTransform, ScaleTransform).ScaleX, 800,, New AniEaseOutFluent(AniEasePower.Strong)), "MyButton Scale " & Uuid)
    End Sub

End Class
