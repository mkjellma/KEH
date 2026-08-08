using System.Diagnostics;
using System.IO.Compression;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace KEHUpdater;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new MainForm());
    }
}

internal sealed class MainForm : Form
{
    private const string Repository = "mkjellma/KEH";
    private const string AddonFolderName = "KjellmanESOHelper";
    private readonly HttpClient http = new();
    private readonly TextBox pathBox = new();
    private readonly Label installedValue = new();
    private readonly Label latestValue = new();
    private readonly Label statusValue = new();
    private readonly Button updateButton = new();
    private readonly Button restoreButton = new();
    private ReleaseInfo? latestRelease;

    public MainForm()
    {
        Text = "KEH Updater";
        ClientSize = new Size(690, 360);
        MinimumSize = new Size(650, 390);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(24, 25, 28);
        ForeColor = Color.WhiteSmoke;
        Font = new Font("Segoe UI", 10F);

        http.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("KEH-Updater", "1.0"));
        http.Timeout = TimeSpan.FromMinutes(5);

        var title = MakeLabel("Kjellman ESO Helper Updater", 20F, Color.FromArgb(244, 194, 73));
        title.SetBounds(24, 18, 630, 40);
        Controls.Add(title);

        var subtitle = MakeLabel("Install and update KEH safely from GitHub Releases.", 10F, Color.Silver);
        subtitle.SetBounds(27, 58, 620, 25);
        Controls.Add(subtitle);

        var pathLabel = MakeLabel("ESO AddOns folder", 9F, Color.Gainsboro);
        pathLabel.SetBounds(27, 94, 250, 22);
        Controls.Add(pathLabel);

        pathBox.SetBounds(27, 118, 535, 30);
        pathBox.Text = FindAddOnsFolder();
        pathBox.BackColor = Color.FromArgb(42, 44, 49);
        pathBox.ForeColor = Color.White;
        pathBox.BorderStyle = BorderStyle.FixedSingle;
        Controls.Add(pathBox);

        var browse = MakeButton("Browse…", Color.FromArgb(72, 82, 95));
        browse.SetBounds(570, 116, 92, 34);
        browse.Click += (_, _) => BrowseForFolder();
        Controls.Add(browse);

        AddInfoRow("Installed version", installedValue, 174);
        AddInfoRow("Latest version", latestValue, 205);
        AddInfoRow("Status", statusValue, 236);

        updateButton.Text = "CHECKING…";
        updateButton.SetBounds(27, 285, 205, 45);
        StyleButton(updateButton, Color.FromArgb(45, 135, 78));
        updateButton.Enabled = false;
        updateButton.Click += async (_, _) => await InstallOrUpdateAsync();
        Controls.Add(updateButton);

        restoreButton.Text = "RESTORE BACKUP";
        restoreButton.SetBounds(242, 285, 190, 45);
        StyleButton(restoreButton, Color.FromArgb(150, 93, 43));
        restoreButton.Click += (_, _) => RestoreLatestBackup();
        Controls.Add(restoreButton);

        var open = MakeButton("OPEN ADDONS FOLDER", Color.FromArgb(55, 91, 135));
        open.SetBounds(442, 285, 220, 45);
        open.Click += (_, _) => OpenAddOnsFolder();
        Controls.Add(open);

        Shown += async (_, _) => await RefreshStatusAsync();
        pathBox.Leave += async (_, _) => await RefreshStatusAsync();
    }

    private static Label MakeLabel(string text, float size, Color color) => new()
    {
        Text = text,
        Font = new Font("Segoe UI", size, size >= 14 ? FontStyle.Bold : FontStyle.Regular),
        ForeColor = color,
        AutoEllipsis = true
    };

    private static Button MakeButton(string text, Color color)
    {
        var button = new Button { Text = text };
        StyleButton(button, color);
        return button;
    }

    private static void StyleButton(Button button, Color color)
    {
        button.FlatStyle = FlatStyle.Flat;
        button.FlatAppearance.BorderSize = 0;
        button.BackColor = color;
        button.ForeColor = Color.White;
        button.Font = new Font("Segoe UI Semibold", 9.5F, FontStyle.Bold);
        button.Cursor = Cursors.Hand;
    }

    private void AddInfoRow(string caption, Label value, int y)
    {
        var label = MakeLabel(caption, 10F, Color.Silver);
        label.SetBounds(27, y, 180, 24);
        Controls.Add(label);
        value.Text = "—";
        value.Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold);
        value.ForeColor = Color.White;
        value.SetBounds(205, y, 455, 24);
        Controls.Add(value);
    }

    private string AddOnsPath => Environment.ExpandEnvironmentVariables(pathBox.Text.Trim());
    private string AddonPath => Path.Combine(AddOnsPath, AddonFolderName);
    private string BackupRoot => Path.Combine(AddOnsPath, "KEH Backups");

    private static string FindAddOnsFolder()
    {
        var candidates = new List<string>();
        var documents = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        if (!string.IsNullOrWhiteSpace(documents))
            candidates.Add(Path.Combine(documents, "Elder Scrolls Online", "live", "AddOns"));
        var profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        candidates.Add(Path.Combine(profile, "Documents", "Elder Scrolls Online", "live", "AddOns"));
        var oneDrive = Environment.GetEnvironmentVariable("OneDrive");
        if (!string.IsNullOrWhiteSpace(oneDrive))
            candidates.Add(Path.Combine(oneDrive, "Documents", "Elder Scrolls Online", "live", "AddOns"));
        return candidates.FirstOrDefault(Directory.Exists) ?? candidates[0];
    }

    private void BrowseForFolder()
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Select the Elder Scrolls Online live\\AddOns folder",
            UseDescriptionForTitle = true,
            InitialDirectory = Directory.Exists(AddOnsPath) ? AddOnsPath : string.Empty
        };
        if (dialog.ShowDialog(this) == DialogResult.OK)
        {
            pathBox.Text = dialog.SelectedPath;
            _ = RefreshStatusAsync();
        }
    }

    private async Task RefreshStatusAsync()
    {
        SetBusy(true, "Checking GitHub…");
        installedValue.Text = ReadInstalledVersion() ?? "Not installed";
        restoreButton.Enabled = GetBackups().Count > 0;
        try
        {
            latestRelease = await GetLatestReleaseAsync();
            latestValue.Text = latestRelease.Version;
            var installed = ReadInstalledVersion();
            bool current = installed is not null && CompareVersions(installed, latestRelease.Version) >= 0;
            statusValue.Text = current ? "KEH is up to date." : installed is null ? "Ready to install." : "An update is available.";
            statusValue.ForeColor = current ? Color.FromArgb(91, 210, 120) : Color.FromArgb(244, 194, 73);
            updateButton.Text = current ? "REINSTALL" : installed is null ? "INSTALL KEH" : "UPDATE KEH";
            updateButton.Enabled = true;
        }
        catch (Exception ex)
        {
            latestValue.Text = "Unavailable";
            statusValue.Text = "Could not contact GitHub: " + ex.Message;
            statusValue.ForeColor = Color.FromArgb(235, 100, 95);
            updateButton.Text = "CHECK AGAIN";
            updateButton.Enabled = true;
            latestRelease = null;
        }
        finally { SetBusy(false); }
    }

    private async Task<ReleaseInfo> GetLatestReleaseAsync()
    {
        using var response = await http.GetAsync($"https://api.github.com/repos/{Repository}/releases/latest");
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStreamAsync());
        var root = json.RootElement;
        var tag = root.GetProperty("tag_name").GetString() ?? throw new InvalidDataException("Release tag is missing.");
        foreach (var asset in root.GetProperty("assets").EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            if (name.StartsWith("KjellmanESOHelper-", StringComparison.OrdinalIgnoreCase) && name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
                return new ReleaseInfo(tag.TrimStart('v', 'V'), asset.GetProperty("browser_download_url").GetString()!, name);
        }
        throw new InvalidDataException("The release has no KEH installation zip.");
    }

    private async Task InstallOrUpdateAsync()
    {
        if (latestRelease is null) { await RefreshStatusAsync(); return; }
        if (Process.GetProcessesByName("eso64").Length > 0)
        {
            MessageBox.Show(this, "Close The Elder Scrolls Online before updating KEH.", "ESO is running", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        if (!Directory.Exists(AddOnsPath))
        {
            MessageBox.Show(this, "Select a valid ESO live\\AddOns folder first.", "Folder not found", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        SetBusy(true, "Downloading and validating release…");
        string tempRoot = Path.Combine(Path.GetTempPath(), "KEH-Updater-" + Guid.NewGuid().ToString("N"));
        string? backupPath = null;
        try
        {
            Directory.CreateDirectory(tempRoot);
            string zipPath = Path.Combine(tempRoot, latestRelease.AssetName);
            await using (var file = File.Create(zipPath))
            await using (var stream = await http.GetStreamAsync(latestRelease.DownloadUrl))
                await stream.CopyToAsync(file);

            string extractPath = Path.Combine(tempRoot, "extract");
            ZipFile.ExtractToDirectory(zipPath, extractPath);
            string stagedSource = Path.Combine(extractPath, AddonFolderName);
            string manifest = Path.Combine(stagedSource, "KjellmanESOHelper.txt");
            if (!File.Exists(manifest)) throw new InvalidDataException("The downloaded archive has an invalid folder structure.");
            string archiveVersion = ReadManifestVersion(manifest) ?? throw new InvalidDataException("The downloaded manifest has no version.");
            if (CompareVersions(archiveVersion, latestRelease.Version) != 0)
                throw new InvalidDataException($"Archive version {archiveVersion} does not match release {latestRelease.Version}.");

            string stagePath = Path.Combine(AddOnsPath, ".KjellmanESOHelper-update-" + Guid.NewGuid().ToString("N"));
            CopyDirectory(stagedSource, stagePath);
            if (Directory.Exists(AddonPath))
            {
                Directory.CreateDirectory(BackupRoot);
                backupPath = Path.Combine(BackupRoot, $"KjellmanESOHelper-{DateTime.Now:yyyyMMdd-HHmmss}");
                Directory.Move(AddonPath, backupPath);
            }
            try { Directory.Move(stagePath, AddonPath); }
            catch
            {
                if (Directory.Exists(stagePath)) Directory.Delete(stagePath, true);
                if (backupPath is not null && Directory.Exists(backupPath) && !Directory.Exists(AddonPath)) Directory.Move(backupPath, AddonPath);
                throw;
            }
            TrimOldBackups(5);
            statusValue.Text = $"KEH {archiveVersion} installed successfully.";
            statusValue.ForeColor = Color.FromArgb(91, 210, 120);
            MessageBox.Show(this, $"KEH {archiveVersion} is installed. Start ESO or use /reloadui if the game was already closed and restarted.", "Update complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            statusValue.Text = "Update failed: " + ex.Message;
            statusValue.ForeColor = Color.FromArgb(235, 100, 95);
            MessageBox.Show(this, ex.Message, "KEH update failed", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally
        {
            try { if (Directory.Exists(tempRoot)) Directory.Delete(tempRoot, true); } catch { }
            SetBusy(false);
            await RefreshStatusAsync();
        }
    }

    private void RestoreLatestBackup()
    {
        if (Process.GetProcessesByName("eso64").Length > 0)
        {
            MessageBox.Show(this, "Close ESO before restoring a backup.", "ESO is running", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        var backups = GetBackups();
        if (backups.Count == 0) return;
        var backup = backups[0];
        if (MessageBox.Show(this, $"Restore {Path.GetFileName(backup)}? The current addon folder will be preserved as a new backup.", "Restore KEH", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return;
        try
        {
            Directory.CreateDirectory(BackupRoot);
            if (Directory.Exists(AddonPath))
                Directory.Move(AddonPath, Path.Combine(BackupRoot, $"KjellmanESOHelper-before-restore-{DateTime.Now:yyyyMMdd-HHmmss}"));
            Directory.Move(backup, AddonPath);
            MessageBox.Show(this, "The latest KEH backup was restored.", "Restore complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
            _ = RefreshStatusAsync();
        }
        catch (Exception ex) { MessageBox.Show(this, ex.Message, "Restore failed", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }

    private void OpenAddOnsFolder()
    {
        try
        {
            Directory.CreateDirectory(AddOnsPath);
            Process.Start(new ProcessStartInfo("explorer.exe", AddOnsPath) { UseShellExecute = true });
        }
        catch (Exception ex) { MessageBox.Show(this, ex.Message, "Could not open folder", MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }

    private string? ReadInstalledVersion() => ReadManifestVersion(Path.Combine(AddonPath, "KjellmanESOHelper.txt"));
    private static string? ReadManifestVersion(string path)
    {
        if (!File.Exists(path)) return null;
        var match = Regex.Match(File.ReadAllText(path), @"(?m)^## Version:\s*([^\r\n]+)");
        return match.Success ? match.Groups[1].Value.Trim() : null;
    }

    private List<string> GetBackups() => Directory.Exists(BackupRoot)
        ? Directory.GetDirectories(BackupRoot, "KjellmanESOHelper-*").OrderByDescending(Directory.GetCreationTimeUtc).ToList()
        : [];

    private void TrimOldBackups(int keep)
    {
        foreach (var path in GetBackups().Skip(keep))
            try { Directory.Delete(path, true); } catch { }
    }

    private static int CompareVersions(string left, string right)
    {
        static Version Parse(string text)
        {
            var clean = Regex.Match(text, @"\d+(?:\.\d+){0,3}").Value;
            return Version.TryParse(clean, out var version) ? version : new Version(0, 0);
        }
        return Parse(left).CompareTo(Parse(right));
    }

    private static void CopyDirectory(string source, string destination)
    {
        Directory.CreateDirectory(destination);
        foreach (var file in Directory.GetFiles(source)) File.Copy(file, Path.Combine(destination, Path.GetFileName(file)), true);
        foreach (var directory in Directory.GetDirectories(source)) CopyDirectory(directory, Path.Combine(destination, Path.GetFileName(directory)));
    }

    private void SetBusy(bool busy, string? status = null)
    {
        UseWaitCursor = busy;
        updateButton.Enabled = !busy;
        restoreButton.Enabled = !busy && GetBackups().Count > 0;
        if (status is not null) statusValue.Text = status;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) http.Dispose();
        base.Dispose(disposing);
    }

    private sealed record ReleaseInfo(string Version, string DownloadUrl, string AssetName);
}
