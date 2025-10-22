# Contributing to Local File Converter

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the problem
- Expected behavior
- Actual behavior
- Screenshots (if applicable)
- macOS version and hardware info

### Suggesting Features

We welcome feature suggestions! Please create an issue with:
- A clear, descriptive title
- Detailed description of the proposed feature
- Use cases and benefits
- Any relevant mockups or examples

### Code Contributions

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/LocalFileConverter.git
   cd LocalFileConverter
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Install dependencies**
   ```bash
   make install-deps
   ```

4. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Keep functions focused and modular

5. **Test your changes**
   ```bash
   make build
   make run
   ```

6. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Include screenshots for UI changes

## Code Style Guidelines

### Swift Style
- Use Swift naming conventions (camelCase for variables/functions, PascalCase for types)
- Maximum line length: 120 characters
- Use `// MARK: -` to organize code sections
- Prefer `let` over `var` when possible
- Use meaningful variable names

### SwiftUI Best Practices
- Extract complex views into separate structs
- Use `@State`, `@Binding`, and `@ObservedObject` appropriately
- Keep view bodies simple and readable

### Comments
- Write self-documenting code when possible
- Add comments for complex logic or non-obvious decisions
- Update comments when code changes

## Project Structure

```
LocalFileConverter/
├── Sources/
│   ├── LocalFileConverterApp.swift    # Main app entry
│   ├── ContentView.swift               # Primary UI
│   ├── Models/                         # Data models
│   ├── Managers/                       # Business logic
│   └── Converters/                     # Conversion implementations
├── Package.swift                       # Dependencies
└── README.md                           # Documentation
```

## Adding New File Formats

To add support for a new file format:

1. **Update the FileType enum** in `Models/ConversionFile.swift`
   - Add the file extension to the appropriate category
   - Update `supportedConversions` array

2. **Implement conversion logic**
   - Add conversion code to the appropriate converter
   - Or create a new converter if needed

3. **Test thoroughly**
   - Test with various file sizes
   - Test error cases
   - Verify output quality

4. **Update documentation**
   - Add format to README.md
   - Update supported formats list

## Development Setup

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- Homebrew

### Quick Start
```bash
# Clone the repo
git clone https://github.com/yourusername/LocalFileConverter.git
cd LocalFileConverter

# Install conversion tools
make install-deps

# Build and run
make run
```

## Testing

Currently, the project doesn't have automated tests, but you should manually test:
- File selection and drag-and-drop
- All supported conversion formats
- Error handling (invalid files, missing tools)
- Progress indicators
- Batch conversions
- Both Intel and Apple Silicon Macs

## Pull Request Process

1. Update documentation if needed
2. Add yourself to contributors list (coming soon)
3. Ensure your code builds without warnings
4. Test on both Intel and Apple Silicon if possible
5. Get approval from maintainers
6. Squash commits before merging (if requested)

## Code of Conduct

### Our Standards
- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards others

### Not Acceptable
- Harassment or discriminatory language
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information
- Unethical or unprofessional conduct

## Questions?

Feel free to:
- Open an issue for discussion
- Reach out to maintainers
- Check existing issues and pull requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making Local File Converter better!
