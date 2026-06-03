using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Windows.Forms;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        if (args.Length < 1 || string.IsNullOrWhiteSpace(args[0]))
        {
            return;
        }

        string inputPath = args[0];
        string fullPath;
        try
        {
            fullPath = Path.GetFullPath(inputPath);
        }
        catch
        {
            fullPath = inputPath;
        }

        string wslPath = ConvertWindowsPathToWslPath(fullPath);
        if (!string.IsNullOrWhiteSpace(wslPath))
        {
            Clipboard.SetText(wslPath);
        }
    }

    private static string ConvertWindowsPathToWslPath(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return string.Empty;
        }

        // Normalize weird Explorer root-background cases such as:
        // D:\.
        // D:\
        // D:
        Match driveRoot = Regex.Match(path, @"^([A-Za-z]):(?:\\\.)?\\?$");
        if (driveRoot.Success)
        {
            string drive = driveRoot.Groups[1].Value.ToLowerInvariant();
            return "/mnt/" + drive;
        }

        // Normal drive path:
        // C:\Users\me -> /mnt/c/Users/me
        Match drivePath = Regex.Match(path, @"^([A-Za-z]):\\(.*)$");
        if (drivePath.Success)
        {
            string drive = drivePath.Groups[1].Value.ToLowerInvariant();
            string rest = drivePath.Groups[2].Value.Replace('\\', '/');
            if (string.IsNullOrWhiteSpace(rest))
            {
                return "/mnt/" + drive;
            }
            return "/mnt/" + drive + "/" + rest;
        }

        // WSL UNC paths:
        // \\wsl.localhost\Ubuntu\home\me -> /home/me
        // \\wsl$\Ubuntu\home\me -> /home/me
        Match wslUnc = Regex.Match(path, @"^\\\\wsl(?:\.localhost|\$)?\\[^\\]+\\(.*)$", RegexOptions.IgnoreCase);
        if (wslUnc.Success)
        {
            return "/" + wslUnc.Groups[1].Value.Replace('\\', '/');
        }

        // Fallback: just normalize slashes.
        return path.Replace('\\', '/');
    }
}
