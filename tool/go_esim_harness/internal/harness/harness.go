package harness

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// Profile represents a simulated eSIM profile hosted on a GSMA SM-DP+ server.
type Profile struct {
	MatchingID     string    `json:"matchingId"`
	ICCID          string    `json:"iccid"`
	SMDPAddress    string    `json:"smdpAddress"`
	LPAString      string    `json:"lpa"`
	PlanName       string    `json:"planName"`
	Status         string    `json:"status"` // available, downloaded, active, released
	SimulatedError string    `json:"simulatedError,omitempty"`
	CreatedAt      time.Time `json:"createdAt"`
}

// Server simulates a GSMA SGP.22 compliant SM-DP+ (Subscription Manager Data Preparation) server.
type Server struct {
	mu          sync.Mutex
	profiles    map[string]*Profile
	hostAddress string
}

func NewServer(hostAddress string) *Server {
	if hostAddress == "" {
		hostAddress = "smdp.mock.telecom"
	}
	return &Server{
		profiles:    make(map[string]*Profile),
		hostAddress: hostAddress,
	}
}

func (s *Server) SetHostAddress(host string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.hostAddress = host
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", s.handleHealthz)
	mux.HandleFunc("/api/esim/order", s.handleOrderProfile)
	mux.HandleFunc("/api/esim/profiles/", s.handleGetProfile)
	mux.HandleFunc("/api/esim/simulate-download", s.handleSimulateDownload)
	mux.HandleFunc("/api/esim/simulate-error", s.handleSimulateError)
	return mux
}

func (s *Server) handleHealthz(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":  "ok",
		"service": "go_esim_harness",
	})
}

func (s *Server) handleOrderProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		PlanName   string `json:"planName"`
		CustomerID string `json:"customerId"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)
	if req.PlanName == "" {
		req.PlanName = "Global Roaming 10GB"
	}

	rawID := make([]byte, 8)
	_, _ = rand.Read(rawID)
	matchingID := "ORD-" + strings.ToUpper(hex.EncodeToString(rawID))

	iccidRaw := make([]byte, 8)
	_, _ = rand.Read(iccidRaw)
	iccid := "8901" + hex.EncodeToString(iccidRaw)[:15]

	s.mu.Lock()
	lpa := fmt.Sprintf("LPA:1$%s$%s", s.hostAddress, matchingID)
	profile := &Profile{
		MatchingID:  matchingID,
		ICCID:       iccid,
		SMDPAddress: s.hostAddress,
		LPAString:   lpa,
		PlanName:    req.PlanName,
		Status:      "available",
		CreatedAt:   time.Now().UTC(),
	}
	s.profiles[matchingID] = profile
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profile)
}

func (s *Server) handleGetProfile(w http.ResponseWriter, r *http.Request) {
	matchingID := strings.TrimPrefix(r.URL.Path, "/api/esim/profiles/")
	s.mu.Lock()
	profile, exists := s.profiles[matchingID]
	s.mu.Unlock()

	if !exists {
		http.Error(w, `{"error":"profile_not_found"}`, http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profile)
}

func (s *Server) handleSimulateDownload(w http.ResponseWriter, r *http.Request) {
	var body struct {
		MatchingID string `json:"matchingId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	s.mu.Lock()
	profile, exists := s.profiles[body.MatchingID]
	if exists {
		profile.Status = "downloaded"
	}
	s.mu.Unlock()

	if !exists {
		http.Error(w, `{"error":"profile_not_found"}`, http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"success": true,
		"profile": profile,
	})
}

func (s *Server) handleSimulateError(w http.ResponseWriter, r *http.Request) {
	var body struct {
		MatchingID string `json:"matchingId"`
		ErrorCode  string `json:"errorCode"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	s.mu.Lock()
	profile, exists := s.profiles[body.MatchingID]
	if exists {
		profile.SimulatedError = body.ErrorCode
	}
	s.mu.Unlock()

	if !exists {
		http.Error(w, `{"error":"profile_not_found"}`, http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"success": true,
		"profile": profile,
	})
}
