package harness_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/flutter-telecom/go_esim_harness/internal/harness"
)

func TestOrderAndProfileLifecycle(t *testing.T) {
	srv := harness.NewServer("smdp.test.io")
	ts := httptest.NewServer(srv.Handler())
	defer ts.Close()

	// 1. Order a new eSIM profile
	orderBody := `{"planName":"Test 5GB Roaming","customerId":"user_42"}`
	resp, err := http.Post(ts.URL+"/api/esim/order", "application/json", strings.NewReader(orderBody))
	if err != nil {
		t.Fatalf("order request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
	}

	var profile harness.Profile
	if err := json.NewDecoder(resp.Body).Decode(&profile); err != nil {
		t.Fatalf("decode failed: %v", err)
	}

	if !strings.HasPrefix(profile.LPAString, "LPA:1$smdp.test.io$ORD-") {
		t.Fatalf("unexpected LPA string: %s", profile.LPAString)
	}
	if profile.Status != "available" {
		t.Fatalf("expected status available, got %s", profile.Status)
	}

	// 2. Fetch the profile by matching ID
	getResp, err := http.Get(ts.URL + "/api/esim/profiles/" + profile.MatchingID)
	if err != nil || getResp.StatusCode != http.StatusOK {
		t.Fatalf("failed to get profile: %v", err)
	}
	_ = getResp.Body.Close()

	// 3. Simulate successful download
	simBody, _ := json.Marshal(map[string]string{"matchingId": profile.MatchingID})
	downResp, err := http.Post(ts.URL+"/api/esim/simulate-download", "application/json", bytes.NewReader(simBody))
	if err != nil || downResp.StatusCode != http.StatusOK {
		t.Fatalf("failed to simulate download: %v", err)
	}
	_ = downResp.Body.Close()

	// 4. Verify updated status
	var updatedProfile harness.Profile
	getUpdated, _ := http.Get(ts.URL + "/api/esim/profiles/" + profile.MatchingID)
	_ = json.NewDecoder(getUpdated.Body).Decode(&updatedProfile)
	_ = getUpdated.Body.Close()

	if updatedProfile.Status != "downloaded" {
		t.Fatalf("expected status downloaded, got %s", updatedProfile.Status)
	}
}

func TestSimulateError(t *testing.T) {
	srv := harness.NewServer("smdp.test.io")
	ts := httptest.NewServer(srv.Handler())
	defer ts.Close()

	resp, _ := http.Post(ts.URL+"/api/esim/order", "application/json", strings.NewReader(`{}`))
	var profile harness.Profile
	_ = json.NewDecoder(resp.Body).Decode(&profile)
	_ = resp.Body.Close()

	errBody, _ := json.Marshal(map[string]string{
		"matchingId": profile.MatchingID,
		"errorCode":  "INSUFFICIENT_MEMORY",
	})
	errResp, err := http.Post(ts.URL+"/api/esim/simulate-error", "application/json", bytes.NewReader(errBody))
	if err != nil || errResp.StatusCode != http.StatusOK {
		t.Fatalf("simulate error failed: %v", err)
	}
	_ = errResp.Body.Close()

	getResp, _ := http.Get(ts.URL + "/api/esim/profiles/" + profile.MatchingID)
	var errProfile harness.Profile
	_ = json.NewDecoder(getResp.Body).Decode(&errProfile)
	_ = getResp.Body.Close()

	if errProfile.SimulatedError != "INSUFFICIENT_MEMORY" {
		t.Fatalf("expected INSUFFICIENT_MEMORY, got %s", errProfile.SimulatedError)
	}
}
