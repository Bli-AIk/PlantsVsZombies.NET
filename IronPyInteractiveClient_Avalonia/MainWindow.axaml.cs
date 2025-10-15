using System;
using System.Collections.Generic;
using System.Linq;
using WebSocketSharp.NetCore;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Text;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Input;
using static IronPyInteractiveDef_Shared.WSEvents;
using System.Threading;
using Avalonia.Threading;

namespace IronPyInteractiveClient_Avalonia;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Task t = new Task(() =>
        {
            for (; ; )
            {
                Thread.Sleep(10000);
                GC.Collect();
            }
        });
        t.Start();
        
        // 设置键盘事件处理
        pyCommandInput.KeyDown += PyCommandInput_KeyDown;
    }

    public delegate void TextAddDelegate(string text, bool isScrollNeeded, long timestamp);
    public TextAddDelegate textAddDelegate;

    private void TextAdd(string s, bool isScrollNeeded, long timestamp)
    {
        mTextOutputPool.AddwithTime(new KeyValuePair<long, string>(timestamp, s));
        mIsTextFlushNeeded = true;
        FlushBoard(true);
    }

    public delegate void CaptionAddDelegate(string caption, bool isFlushNeeded);
    public CaptionAddDelegate captionAddDelegate;
    private void CaptionAdd(string newCaption, bool isFlushNeeded)
    {
        pyCaption.Text = newCaption;
        if (isFlushNeeded) { FlushBoard(false); }
    }

    public delegate void ExecutionCompletedDelegate(object exception);
    public ExecutionCompletedDelegate executionCompletedDelegate;
    private void ExecutionCompleted(object exception)
    {
        pyPromptSign.Text = mPromptStr_Rest;
        mTextOutputHiddenSuffix += ">>> ";
    }

    private void WSConnect(string addr)
    {
        ws = new WebSocket(addr);
        ws.OnMessage += (sender, e) =>
        {
            executionCompletedDelegate = new ExecutionCompletedDelegate(ExecutionCompleted);
            textAddDelegate = new TextAddDelegate(TextAdd);
            try
            {
                JObject jo = JObject.Parse(e.Data);
                WSEvent wsEvent = jo.ToObject<WSEvent>();
                switch (wsEvent.eventtype)
                {
                    case "output":
                        OutputEvent outputEvent = jo.ToObject<OutputEvent>();
                        Dispatcher.UIThread.Invoke(() => 
                            TextAdd(outputEvent.msg, true, outputEvent.timestamp));
                        break;
                    case "execution":
                        ExecutionEvent executionEvent = jo.ToObject<ExecutionEvent>();
                        Dispatcher.UIThread.Invoke(() => 
                            TextAdd((
                                executionEvent.statuscode == ExecutionEventResult.error
                                ? $"{executionEvent.errortype}: {executionEvent.result}\n"
                                : (executionEvent.result != null ? $"{executionEvent.result}\n" : "")
                            ), true, executionEvent.timestamp));
                        Dispatcher.UIThread.Invoke(() => 
                            ExecutionCompleted(executionEvent.errortype));
                        break;
                }
            }
            catch (Exception ex)
            {
                // Avalonia doesn't have MessageBox, so we'll add to output instead
                Dispatcher.UIThread.Invoke(() =>
                    TextAdd($"Error: {ex.GetType()}: {ex.Message}\n", true, DateTimeOffset.Now.ToUnixTimeMilliseconds()));
            }
        };
        ws.OnClose += (sender, e) =>
        {
            captionAddDelegate = new CaptionAddDelegate(CaptionAdd);
            mWSConnected = false;
            Dispatcher.UIThread.Invoke(() => CaptionAdd("Connection Closed", true));
        };
        ws.OnError += (sender, e) =>
        {
            captionAddDelegate = new CaptionAddDelegate(CaptionAdd);
            Dispatcher.UIThread.Invoke(() => CaptionAdd($"Error:{e}", true));
        };

        mWSConnected = true;
        ws.Connect();
    }

    private void Button_Click(object sender, RoutedEventArgs e)
    {
        TextAdd(mTextOutputHiddenSuffix + pyCommandInput.Text + "\n", true, mTextOutputPool.Last().Key + 1);
        mTextOutputHiddenSuffix = "";
        pyPromptSign.Text = mPromptStr_Working;
        ws.SendAsync(pyCommandInput.Text, e => { });
        pyCommandInput.Text = "";
    }

    private WebSocket ws;

    private void PyCommandInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter && e.KeyModifiers == KeyModifiers.Control)
        {
            if (mWSConnected)
            {
                Button_Click(sender, new RoutedEventArgs());
            }
            e.Handled = true;
        }
    }

    public void FlushBoard(bool isScrollNeeded)
    {
        pyOutput.Text = TextJoin();
        wsConnBtn.Content = !mWSConnected ? "Connect" : "Disconnect";
        if (!mWSConnected)
        {
            pyPromptSign.Text = mPromptStr_NotAvailable;
        }
        if (pyCommandSendBtn != null) { pyCommandSendBtn.IsEnabled = mWSConnected; }
        if (isScrollNeeded) scrollText.ScrollToEnd();
    }

    private string TextJoin()
    {
        StringBuilder stringBuilder = new StringBuilder();
        foreach (var kv in mTextOutputPool.RangeFromTime(DateTimeOffset.Now.AddHours(-24.0).ToUnixTimeMilliseconds(), DateTimeOffset.Now.ToUnixTimeMilliseconds()))
        {
            stringBuilder.Append(kv.Value);
        }
        return stringBuilder.ToString();
    }

    private void WsConnBtn_Click(object sender, RoutedEventArgs e)
    {
        if (!mWSConnected)
        {
            WSConnect(wsAddrInput.Text);
            pyCaption.Text = "Connecting...";
        }
        else
        {
            ws.Close();
            mWSConnected = false;
            pyCaption.Text = "Connection Closed";
        }
        FlushBoard(false);
    }

    private void Btn_clearScreen_Click(object sender, RoutedEventArgs e)
    {
        mTextOutputPool.Clear();
        FlushBoard(false);
    }

    // 从原WPF项目复制的成员变量和常量
    private TextQueueList mTextOutputPool = new TextQueueList();
    private bool mIsTextFlushNeeded = false;
    private bool mWSConnected = false;
    private string mTextOutputHiddenSuffix = "";
    private const string mPromptStr_Rest = ">>>";
    private const string mPromptStr_Working = "...";
    private const string mPromptStr_NotAvailable = "   ";

    internal class TextQueueList : List<KeyValuePair<long, string>>
    {
        public void AddwithTime(KeyValuePair<long, string> item)
        {
            long k = item.Key;
            if (Count == 0 || k >= this[^1].Key)
            {
                Add(item);
                return;
            }
            if (k <= this[0].Key)
            {
                Insert(0, item);
                return;
            }
            int mi = 0, ma = Count, a = 0, b = 0, i = 0;
            int cmpresult;
            for (; ; )
            {
                a = (ma - mi) / 2;
                b = ma - mi - a;
                i = mi + a;
                cmpresult = this[i].Key.CompareTo(k);
                if (cmpresult == 0)
                {
                    Insert(i, item);
                    return;
                }
                else if (cmpresult < 0)
                {
                    if (b <= 1)
                    {
                        Insert(i + 1, item);
                        return;
                    }
                    mi = i;
                }
                else if (cmpresult > 0)
                {
                    if (a <= 1)
                    {
                        Insert(i, item);
                        return;
                    }
                    ma = i;
                }
            }
        }

        public IEnumerable<KeyValuePair<long, string>> RangeFromTime(long startTime, long endTime)
        {
            return this.Where(kv => kv.Key >= startTime && kv.Key <= endTime);
        }
    }
}