using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Maui.Controls;

namespace Procesamiento;

public partial class MainPage : ContentPage
{
    private ProcessingResult? _result;
    private List<WordItem> _allWords = new();
    private const double MaxBarWidth = 70.0;

    public MainPage()
    {
        InitializeComponent();
    }

    private async void OnProcessClicked(object sender, EventArgs e)
    {
        ProcessBtn.IsEnabled = false;
        Spinner.IsVisible = true;
        Spinner.IsRunning = true;
        ProcessingLabel.IsVisible = true;
        TimeBox.IsVisible = false;
        StatsGrid.IsVisible = false;
        ChartBox.IsVisible = false;
        ModalBtnBox.IsVisible = false;

        await Task.Delay(50); // Permitir UI update

        var text = await LoadTextAsync();

        _result = await Task.Run(() => ProcessingEngine.Process(text));

        // Tiempo
        TimeLabel.Text = $"{_result.ProcessingTimeMs:F2} ms";
        TimeBox.IsVisible = true;

        // Stats
        WordCountLabel.Text = _result.WordCount.ToString("N0");
        SentenceCountLabel.Text = _result.SentenceCount.ToString("N0");
        ParaCountLabel.Text = _result.ParagraphCount.ToString("N0");
        UniqueCountLabel.Text = _result.WordFrequency.Count.ToString("N0");
        StatsGrid.IsVisible = true;

        // Top 10 chart
        BuildChart(_result.WordFrequency);
        ChartBox.IsVisible = true;

        // Botón modal
        ShowModalBtn.Text = $"📋  Ver Todas las Palabras ({_result.WordFrequency.Count:N0})";
        ModalBtnBox.IsVisible = true;

        // Preparar datos para lista
        double maxCount = _result.WordFrequency.FirstOrDefault().Count;
        _allWords = _result.WordFrequency
            .Select((kv, i) => new WordItem
            {
                Index = i + 1,
                Word = kv.Word,
                Count = kv.Count,
                BarWidth = maxCount > 0 ? (kv.Count / maxCount) * MaxBarWidth : 0
            }).ToList();
        WordList.ItemsSource = _allWords;

        Spinner.IsRunning = false;
        Spinner.IsVisible = false;
        ProcessingLabel.IsVisible = false;
        ProcessBtn.IsEnabled = true;
    }

    private void BuildChart(List<(string Word, int Count)> wordFrequency)
    {
        ChartStack.Children.Clear();
        var top10 = wordFrequency.Take(10).ToList();
        double maxCount = top10.FirstOrDefault().Count;

        foreach (var (word, count) in top10)
        {
            double ratio = maxCount > 0 ? count / maxCount : 0;

            var row = new Grid
            {
                ColumnDefinitions = { new ColumnDefinition(90), new ColumnDefinition(GridLength.Star), new ColumnDefinition(50) }
            };

            var wordLabel = new Label { Text = word, TextColor = Colors.White, FontSize = 11, VerticalOptions = LayoutOptions.Center };
            var track = new Border
            {
                BackgroundColor = Color.FromArgb("#ffffff1a"),
                StrokeShape = new Microsoft.Maui.Controls.Shapes.RoundRectangle { CornerRadius = 7 },
                HeightRequest = 14,
                VerticalOptions = LayoutOptions.Center,
                Content = new BoxView
                {
                    Color = Color.FromArgb("#e94560"),
                    HorizontalOptions = LayoutOptions.Start,
                    WidthRequest = ratio * 200
                }
            };
            var countLabel = new Label { Text = count.ToString("N0"), TextColor = Color.FromArgb("#a8dadc"), FontSize = 11, HorizontalOptions = LayoutOptions.End, VerticalOptions = LayoutOptions.Center };

            row.Add(wordLabel, 0, 0);
            row.Add(track, 1, 0);
            row.Add(countLabel, 2, 0);
            ChartStack.Children.Add(row);
        }
    }

    private async Task<string> LoadTextAsync()
    {
        using var stream = await FileSystem.OpenAppPackageFileAsync("quijote.txt");
        using var reader = new System.IO.StreamReader(stream, System.Text.Encoding.UTF8);
        return await reader.ReadToEndAsync();
    }

    private void OnShowModalClicked(object sender, EventArgs e)
    {
        ModalOverlay.IsVisible = true;
        SearchBar.Text = "";
        WordList.ItemsSource = _allWords;
    }

    private void OnCloseModalClicked(object sender, EventArgs e)
    {
        ModalOverlay.IsVisible = false;
    }

    private void OnSearchChanged(object sender, TextChangedEventArgs e)
    {
        var query = e.NewTextValue?.ToLowerInvariant() ?? "";
        WordList.ItemsSource = string.IsNullOrEmpty(query)
            ? _allWords
            : _allWords.Where(w => w.Word.Contains(query)).ToList();
    }
}

public class WordItem
{
    public int Index { get; set; }
    public string Word { get; set; } = "";
    public int Count { get; set; }
    public double BarWidth { get; set; }
}
