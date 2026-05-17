package extract

import (
	"fmt"
	"path/filepath"
	"sort"
	"strings"

	"github.com/overdrive-dev/hermes-aihaus/aih-graph/internal/types"
)

// skillFrontmatter mirrors the YAML frontmatter declared by every Hermes
// SKILL.md under pkg/hermes/skills/*/.
type skillFrontmatter struct {
	Name                   string `yaml:"name"`
	Description            string `yaml:"description"`
	DisableModelInvocation bool   `yaml:"disable-model-invocation"`
	AllowedTools           any    `yaml:"allowed-tools"` // CSV string or YAML list
	ArgumentHint           string `yaml:"argument-hint"`
}

// ParseSkillsDir walks the current Hermes skill package and the historical
// pkg/.aihaus skill tree. Files without YAML frontmatter or without a name are
// skipped.
func ParseSkillsDir(repoRoot string) ([]types.Skill, error) {
	patterns := []string{
		filepath.Join(repoRoot, "pkg", "hermes", "skills", "*", "SKILL.md"),
		filepath.Join(repoRoot, "pkg", ".aihaus", "skills", "aih-*", "SKILL.md"),
	}
	var matches []string
	for _, pattern := range patterns {
		found, err := filepath.Glob(pattern)
		if err != nil {
			return nil, fmt.Errorf("glob skills: %w", err)
		}
		matches = append(matches, found...)
	}
	sort.Strings(matches)

	skills := make([]types.Skill, 0, len(matches))
	for _, path := range matches {
		var fm skillFrontmatter
		_, err := parseFrontmatterInto(path, &fm)
		if err != nil {
			return nil, fmt.Errorf("parse %s: %w", path, err)
		}
		if fm.Name == "" {
			continue
		}
		if !strings.HasPrefix(fm.Name, "aih-") && !strings.HasPrefix(fm.Name, "aihaus-") {
			// aihaus skill names must use a recognized package prefix.
			continue
		}
		skills = append(skills, types.Skill{
			Name:                   fm.Name,
			Description:            fm.Description,
			DisableModelInvocation: fm.DisableModelInvocation,
			AllowedTools:           toolsToSlice(fm.AllowedTools),
			ArgumentHint:           fm.ArgumentHint,
		})
	}
	return skills, nil
}
