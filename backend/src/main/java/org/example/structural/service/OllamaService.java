package org.example.structural.service;

import org.example.structural.dto.OllamaRequest;
import org.example.structural.dto.OllamaResponse;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class OllamaService {

    private static final String OLLAMA_URL = "http://localhost:11434/api/generate";
    private final RestTemplate restTemplate = new RestTemplate();

    public String generateResponse(String prompt, String systemContext) {
        OllamaRequest request = OllamaRequest.builder()
                .model("llama3")
                .prompt(prompt)
                .system(systemContext)
                .stream(false)
                .build();

        try {
            OllamaResponse response = restTemplate.postForObject(
                    OLLAMA_URL,
                    request,
                    OllamaResponse.class
            );
            return response != null ? response.getResponse() : "No response from AI.";
        } catch (Exception e) {
            return "Error connecting to Ollama: " + e.getMessage();
        }
    }
}