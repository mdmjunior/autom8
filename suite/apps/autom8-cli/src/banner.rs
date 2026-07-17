use std::io::IsTerminal;

const AUTO_COLOR: &str = "\u{1b}[38;5;255m";
const M_COLOR: &str = "\u{1b}[38;5;45m";
const EIGHT_COLOR: &str = "\u{1b}[38;5;39m";
const RESET_COLOR: &str = "\u{1b}[0m";

const BANNER: [(&str, &str, &str); 5] = [
    ("    ___         __      ", "  __  ", "_______"),
    ("   /   | __  __/ /_____ ", " /  |/  ", "( __ )"),
    ("  / /| |/ / / / __/ __ \\", "/ /|_/ ", "/ __  |"),
    (" / ___ / /_/ / /_/ /_/ /", " /  / ", "/ /_/ /"),
    ("/_/  |_\\__,_/\\__/\\____/", "_/  /_/", "\\____/"),
];

#[must_use]
pub fn color_is_enabled(no_color: bool) -> bool {
    !no_color
        && std::io::stdout().is_terminal()
        && std::env::var_os("NO_COLOR").is_none()
        && std::env::var("TERM").map_or(true, |term| term != "dumb")
}

#[must_use]
pub fn render(colored: bool) -> String {
    let mut output = String::new();

    for (auto, m, eight) in BANNER {
        if colored {
            output.push_str(AUTO_COLOR);
            output.push_str(auto);
            output.push_str(M_COLOR);
            output.push_str(m);
            output.push_str(EIGHT_COLOR);
            output.push_str(eight);
            output.push_str(RESET_COLOR);
        } else {
            output.push_str(auto);
            output.push_str(m);
            output.push_str(eight);
        }

        output.push('\n');
    }

    output
}

#[cfg(test)]
mod tests {
    use super::render;

    #[test]
    fn plain_banner_has_five_lines_and_no_ansi_sequences() {
        let banner = render(false);

        assert_eq!(banner.lines().count(), 5);
        assert!(!banner.contains("\u{1b}["));
        assert!(banner.lines().all(|line| line.chars().count() <= 40));
    }

    #[test]
    fn colored_banner_contains_ansi_sequences() {
        assert!(render(true).contains("\u{1b}[38;5;45m"));
    }
}
