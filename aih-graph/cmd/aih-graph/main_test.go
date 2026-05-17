package main

import "testing"

func TestBuildEmbedProviderSupportsOllama(t *testing.T) {
	provider, err := buildEmbedProvider("ollama")
	if err != nil {
		t.Fatalf("buildEmbedProvider(ollama) returned error: %v", err)
	}
	if provider.Model() != "ollama:nomic-embed-text" {
		t.Fatalf("model = %q, want ollama:nomic-embed-text", provider.Model())
	}
	if provider.Dim() != 768 {
		t.Fatalf("dim = %d, want 768", provider.Dim())
	}
}
