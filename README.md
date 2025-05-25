# Obrasa Tree Mutator GitHub Action

A GitHub Action that runs mutation testing on your codebase using the [Obrasa Tree Mutator](https://github.com/obrasa/tree-mutator). This action downloads the pre-built binary from releases and runs mutation testing based on your configuration.

## Features

- 🚀 **Easy Setup**: Just add the action to your workflow - no dependencies to install
- ⚡ **Fast**: Uses pre-built binary, no compilation or dependency installation required
- 🔧 **Configurable**: Specify your own `obrasa.yaml` configuration file
- 📊 **Rich Reports**: Generates HTML, JSON, and Markdown mutation reports
- 🏷️ **Version Control**: Pin to specific tree-mutator versions or use latest
- 📈 **CI Integration**: Outputs mutation score for use in other workflow steps
- 🔒 **Private Repository Support**: Works with private tree-mutator repository
- 🌐 **Cross-Platform**: Supports Linux and macOS runners
- 🧩 **Modular**: Clean script-based architecture for easy maintenance

## Supported Languages

The tree-mutator supports mutation testing for:
- Python
- JavaScript/TypeScript
- Java
- C/C++
- Rust
- Go
- Ruby
- Lisp
- C#

## Usage

### Basic Usage

```yaml
name: Mutation Testing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  mutation-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Mutation Testing
      uses: obrasa/tree-mutator@v1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        config-path: 'obrasa.yaml'
```

### Advanced Usage

```yaml
name: Mutation Testing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  mutation-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Mutation Testing
      id: mutation-test
      uses: obrasa/tree-mutator@v1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        config-path: 'config/obrasa.yaml'
        version: 'v1.2.0'
        target-score: 80
    
    - name: Comment PR with Results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const score = '${{ steps.mutation-test.outputs.mutation-score }}';
          const targetMet = '${{ steps.mutation-test.outputs.target-met }}' === 'true';
          const body = `## 🧬 Mutation Testing Results
          
          **Mutation Score:** ${score}%
          **Target:** 80%
          **Status:** ${targetMet ? '✅ Target met' : '❌ Below target'}
          
          ${targetMet ? '✅ Great job! Your code is well tested.' : '⚠️ Consider adding more tests to improve mutation score.'}
          
          📊 [View detailed report](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: body
          });
```

### Usage with Target Score

```yaml
name: Mutation Testing with Quality Gate

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  mutation-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Mutation Testing
      uses: obrasa/tree-mutator@v1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        config-path: 'obrasa.yaml'
        target-score: 85  # Fail if mutation score is below 85%
    
    # This step will only run if mutation score meets the target
    - name: Deploy to Production
      run: echo "Deploying to production..."
```

### Multi-Platform Testing

```yaml
name: Cross-Platform Mutation Testing

on:
  push:
    branches: [ main ]

jobs:
  mutation-test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Mutation Testing
      uses: obrasa/tree-mutator@v1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        config-path: 'obrasa.yaml'
        target-score: 75
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `config-path` | Path to the obrasa.yaml configuration file | No | `obrasa.yaml` |
| `version` | Version of tree-mutator to use (e.g., v1.0.0) | No | `latest` |
| `github-token` | GitHub token for downloading private repository releases | Yes | - |
| `target-score` | Target mutation score percentage (e.g., 80). If set, the action will fail if the score is below this threshold | No | - |

## Outputs

| Output | Description |
|--------|-------------|
| `mutation-score` | The mutation score percentage (e.g., "85.2") |
| `report-json` | Path to the generated JSON mutation report |
| `report-html` | Path to the generated HTML mutation report |
| `report-markdown` | Path to the generated Markdown mutation report |
| `target-met` | Whether the mutation score met the target threshold (true/false) |

## Configuration File

Create an `obrasa.yaml` file in your repository to configure the mutation testing:

```yaml
# obrasa.yaml
source: 
  - src
  - lib

test:
  command: pytest --tb=short
  timeout: 300

file_selection_strategy:
  type: random

mutations:
  - string_prefix
  - arithmetic_negation
  - boolean_operator
  - conditional_boundary

exclude:
  - "**/test_*"
  - "**/__pycache__/**"

output:
  directory: ./mutation-results
  report: ./mutation-report
  formats: [json, html, markdown]
```

### Configuration Options

- **source**: List of directories to scan for mutations
- **test**: Test command and timeout configuration
- **file_selection_strategy**: Strategy for selecting files to mutate (random, weighted, hotspot)
- **mutations**: List of mutation operators to apply
- **exclude**: Patterns to exclude from mutation
- **output**: Report generation configuration

## Examples

### Python Project

```yaml
# obrasa.yaml for Python project
source:
  - src

test:
  command: python -m pytest tests/ -v
  timeout: 600

file_selection_strategy:
  type: random

mutations:
  - string_prefix
  - arithmetic_negation
  - python_none_replacement

exclude:
  - "**/test_*.py"
  - "**/*_test.py"

output:
  directory: ./mutation-results
  report: ./mutation-report
  formats: [json, html]
```

### JavaScript/Node.js Project

```yaml
# obrasa.yaml for JavaScript project
source:
  - src
  - lib

test:
  command: npm test
  timeout: 300

file_selection_strategy:
  type: weighted

mutations:
  - string_prefix
  - increment_decrement_swap

exclude:
  - "**/*.test.js"
  - "**/*.spec.js"

output:
  directory: ./mutation-results
  report: ./mutation-report
  formats: [json, html, markdown]
```

## Binary Download

The action automatically detects your runner's platform and downloads the appropriate binary:

- **Linux x86_64**: `mutator-linux-amd64`
- **macOS x86_64**: `mutator-macos-amd64`
- **macOS ARM64**: `mutator-macos-arm64`

**Coming Soon**: Linux ARM64 support will be enabled when GitHub's native ARM64 runners become available for private repositories.

### Platform Detection and Fallbacks

The action uses intelligent platform detection:

1. **Native Architecture First**: Downloads the binary matching your exact platform and architecture
2. **Automatic Fallbacks**: If the native binary isn't available, falls back to compatible alternatives:
   - ARM64 systems can use x86_64 binaries (via emulation/Rosetta)
   - Provides clear messaging about which binary is being used

### Supported GitHub Runners

| Runner | Platform | Architecture | Binary Used | Build Method | Status |
|--------|----------|--------------|-------------|--------------|--------|
| `ubuntu-latest` | Linux | x86_64 | `mutator-linux-amd64` | Native | ✅ Available |
| `macos-13` | macOS | x86_64 | `mutator-macos-amd64` | Native | ✅ Available |
| `macos-latest` | macOS | ARM64 | `mutator-macos-arm64` | Native | ✅ Available |
| `macos-14` | macOS | ARM64 | `mutator-macos-arm64` | Native | ✅ Available |
| `ubuntu-24.04-arm` | Linux | ARM64 | `mutator-linux-arm64` | Native | 🚧 Coming Soon* |
| `ubuntu-22.04-arm` | Linux | ARM64 | `mutator-linux-arm64` | Native | 🚧 Coming Soon* |

**\* Coming Soon**: Linux ARM64 runners are available for public repositories but not yet for private repositories. We'll enable this as soon as GitHub makes them available for private repos.

### Performance Benefits

With native runners, you get:

- **🚀 Faster builds**: No emulation overhead
- **💰 Cost effective**: Free for public repositories  
- **🔋 Energy efficient**: ARM64 uses 30-40% less power
- **📊 Better resources**: 4 vCPU, 16 GB RAM for public repos
- **🎯 True native**: Real native performance, not emulated

## Artifacts

The action automatically uploads mutation reports as GitHub artifacts:

- `mutation-report.html` - Interactive HTML report
- `mutation-report.json` - Machine-readable JSON report  
- `mutation-report.md` - Markdown summary report

These artifacts are retained for 30 days and can be downloaded from the Actions tab.

## Permissions

Make sure your workflow has the necessary permissions:

```yaml
permissions:
  contents: read
  pull-requests: write  # If you want to comment on PRs
```

## Troubleshooting

### Common Issues

1. **Configuration file not found**
   - Ensure the `config-path` points to the correct location
   - Check that the file is committed to your repository

2. **Permission denied when downloading tree-mutator**
   - Verify that `GITHUB_TOKEN` has access to the private repository
   - For organization repositories, you may need a personal access token

3. **Binary not found in release**
   - Check that the release contains the expected binary assets
   - The action will list available assets if the expected binary is not found

4. **Tests failing during mutation testing**
   - Ensure your test command works in the CI environment
   - Check test timeouts and dependencies

5. **Low mutation score**
   - Review the HTML report to see which mutations survived
   - Add tests to cover the uncaught mutations

### Debug Mode

To enable debug logging, add this to your workflow:

```yaml
- name: Run Mutation Testing
  uses: obrasa/tree-mutator@v1
  env:
    ACTIONS_STEP_DEBUG: true
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    config-path: 'obrasa.yaml'
```

## Performance

This action is significantly faster than previous versions because:

- ⚡ **No dependency installation**: Uses pre-built binaries
- 🚫 **No Python/Poetry setup**: Eliminates environment setup time
- 📦 **Smaller downloads**: Only downloads the binary, not entire source code
- 🔄 **Faster startup**: Binary execution is immediate

Typical performance improvements:
- **Setup time**: Reduced from ~2-3 minutes to ~10-30 seconds
- **Total runtime**: 60-80% faster for most projects

## Architecture

This action uses a clean, modular script-based architecture:

```
├── action.yml              # Main action definition
├── scripts/
│   ├── download-binary.sh   # Downloads the appropriate binary
│   └── run-mutator.sh       # Runs mutation testing and processes results
└── README.md
```

### Scripts

- **`download-binary.sh`**: Handles platform detection and binary downloading with fallback mechanisms
- **`run-mutator.sh`**: Executes the mutation testing and extracts results for GitHub Actions outputs

This modular approach makes the action easier to:
- 🔧 **Maintain**: Each script has a single responsibility
- 🐛 **Debug**: Issues can be isolated to specific components
- 🧪 **Test**: Scripts can be tested independently
- 📖 **Understand**: Clean separation of concerns

## Contributing

Issues and pull requests are welcome! Please see the [tree-mutator repository](https://github.com/obrasa/tree-mutator) for the core mutation testing engine.

## License

This action is distributed under the same license as the tree-mutator project.
