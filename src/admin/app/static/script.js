// Helper function to get DB config from the RDS Endpoint input field
function getDbConfig() {
  const rdsEndpoint = document.getElementById("db-endpoint").value;
  return {
    database_url: `${rdsEndpoint}:5432/musive`,
    username: "postgres",
    password: "1234567890"
  };
}

// Function to ensure URLs have a trailing question mark
function ensureUrlEndsWithQuestionMark(url) {
  return url.endsWith('?') ? url : `${url}?`;
}

// Initialize Database API call
async function initializeDatabase() {
  const requestBody = {
    database_url: document.getElementById("db-endpoint").value,
    username: "postgres",
    password: "1234567890",
    db_name: "musive",
    port: 5432
  };

  try {
    const response = await fetch("/initialize", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const result = await response.json();
    console.log("Database initialized:", result);
    document.getElementById("initialize-output").innerText = "Database initialized successfully!";
  } catch (error) {
    console.error("Error initializing database:", error);
    document.getElementById("initialize-output").innerText = "Error initializing database!";
  }
}

// Create Artist API call
async function createArtist() {
  const requestBody = {
    artist: {
      id: document.getElementById("artist-id").value,
      username: document.getElementById("artist-username").value,
      display_name: document.getElementById("artist-displayname").value,
      avatar: {
        url: ensureUrlEndsWithQuestionMark(document.getElementById("artist-avatar-url").value),
        color: document.getElementById("artist-avatar-color").value
      },
      gender: document.getElementById("artist-gender").value
    },
    config: getDbConfig()
  };

  try {
    const response = await fetch("/artists", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const result = await response.json();
    console.log("Artist created:", result);
    document.getElementById("artist-output").innerText = "Artist created successfully!";
  } catch (error) {
    console.error("Error creating artist:", error);
    document.getElementById("artist-output").innerText = "Error creating artist!";
  }
}

// Create Track API call
async function createTrack() {
  const requestBody = {
    track: {
      id: document.getElementById("track-id").value,
      user_id: document.getElementById("user-id").value,
      track_name: document.getElementById("track-name").value,
      duration: document.getElementById("track-duration").value,
      download_url: ensureUrlEndsWithQuestionMark(document.getElementById("track-download-url").value),
      src: ensureUrlEndsWithQuestionMark(document.getElementById("track-src").value),
      cover_image: {
        url: ensureUrlEndsWithQuestionMark(document.getElementById("track-cover-url").value),
        color: document.getElementById("track-cover-color").value
      }
    },
    config: getDbConfig()
  };

  try {
    const response = await fetch("/tracks", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const result = await response.json();
    console.log("Track created:", result);
    document.getElementById("track-output").innerText = "Track created successfully!";
  } catch (error) {
    console.error("Error creating track:", error);
    document.getElementById("track-output").innerText = "Error creating track!";
  }
}

// Update Artist API call
async function updateArtist() {
  const username = document.getElementById("artist-username-update").value;

  const requestBody = {
    artist_update: {
      avatar: {
        url: ensureUrlEndsWithQuestionMark(document.getElementById("artist-avatar-url-update").value),
        color: document.getElementById("artist-avatar-color-update").value
      }
    },
    config: getDbConfig()
  };

  try {
    const response = await fetch(`/artists/${username}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const result = await response.json();
    console.log("Artist updated:", result);
    document.getElementById("update-artist-output").innerText = "Artist updated successfully!";
  } catch (error) {
    console.error("Error updating artist:", error);
    document.getElementById("update-artist-output").innerText = "Error updating artist!";
  }
}

// Update Track API call
async function updateTrack() {
  const trackName = document.getElementById("track-name-update").value;

  const requestBody = {
    track_update: {
      download_url: ensureUrlEndsWithQuestionMark(document.getElementById("track-download-url-update").value),
      src: ensureUrlEndsWithQuestionMark(document.getElementById("track-src-update").value),
      cover_image: {
        url: ensureUrlEndsWithQuestionMark(document.getElementById("track-cover-url-update").value),
        color: document.getElementById("track-cover-color-update").value
      }
    },
    config: getDbConfig()
  };

  try {
    const response = await fetch(`/tracks/${trackName}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const result = await response.json();
    console.log("Track updated:", result);
    document.getElementById("update-track-output").innerText = "Track updated successfully!";
  } catch (error) {
    console.error("Error updating track:", error);
    document.getElementById("update-track-output").innerText = "Error updating track!";
  }
}

// Tab functionality
const tabButtons = document.querySelectorAll('.tab-button');
const tabContents = document.querySelectorAll('.tab-content');

function switchTab(tabId) {
  // Remove active class from all buttons and contents
  tabButtons.forEach(button => button.classList.remove('active'));
  tabContents.forEach(content => content.classList.remove('active'));

  // Add active class to selected button and content
  document.querySelector(`[data-tab="${tabId}"]`).classList.add('active');
  document.getElementById(tabId).classList.add('active');
}

// Add click event listeners to tab buttons
tabButtons.forEach(button => {
  button.addEventListener('click', () => {
    switchTab(button.dataset.tab);
  });
});

// Event listeners for buttons
document.getElementById("initialize-db").addEventListener("click", initializeDatabase);
document.getElementById("create-artist-btn").addEventListener("click", createArtist);
document.getElementById("create-track-btn").addEventListener("click", createTrack);
document.getElementById("update-artist-btn").addEventListener("click", updateArtist);
document.getElementById("update-track-btn").addEventListener("click", updateTrack);