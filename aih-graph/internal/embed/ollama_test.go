package embed

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestOllamaProviderEmbedsWithConfiguredEndpointAndModel(t *testing.T) {
	var gotPath string
	var gotModel string
	var gotPrompt string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		if r.Method != http.MethodPost {
			t.Fatalf("method = %s, want POST", r.Method)
		}
		var req struct {
			Model  string `json:"model"`
			Prompt string `json:"prompt"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		gotModel = req.Model
		gotPrompt = req.Prompt
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"embedding":[0.25,-0.5,0.75]}`))
	}))
	defer server.Close()

	provider, err := NewOllamaProvider(OllamaOptions{
		Endpoint: server.URL,
		Model:    "nomic-embed-text",
		Dim:      3,
	})
	if err != nil {
		t.Fatalf("NewOllamaProvider returned error: %v", err)
	}

	vec, err := provider.Embed("aihaus memory")
	if err != nil {
		t.Fatalf("Embed returned error: %v", err)
	}

	if gotPath != "/api/embeddings" {
		t.Fatalf("path = %q, want /api/embeddings", gotPath)
	}
	if gotModel != "nomic-embed-text" {
		t.Fatalf("model = %q", gotModel)
	}
	if gotPrompt != "aihaus memory" {
		t.Fatalf("prompt = %q", gotPrompt)
	}
	if provider.Model() != "ollama:nomic-embed-text" {
		t.Fatalf("provider model = %q", provider.Model())
	}
	if provider.Dim() != 3 {
		t.Fatalf("dim = %d", provider.Dim())
	}
	want := []float32{0.25, -0.5, 0.75}
	for i := range want {
		if vec[i] != want[i] {
			t.Fatalf("vec[%d] = %v, want %v", i, vec[i], want[i])
		}
	}
}

func TestOllamaProviderRejectsUnexpectedDimension(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"embedding":[1,2]}`))
	}))
	defer server.Close()

	provider, err := NewOllamaProvider(OllamaOptions{Endpoint: server.URL, Model: "nomic-embed-text", Dim: 3})
	if err != nil {
		t.Fatalf("NewOllamaProvider returned error: %v", err)
	}
	_, err = provider.Embed("bad dimension")
	if err == nil || !strings.Contains(err.Error(), "dimension") {
		t.Fatalf("expected dimension error, got %v", err)
	}
}
