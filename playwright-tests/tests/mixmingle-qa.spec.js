const { test, expect } = require('@playwright/test');

// Base URL for the app
const BASE_URL = 'https://mix-and-mingle-62061.web.app';

// Test user credentials (use environment variables in production)
const TEST_EMAIL = process.env.TEST_EMAIL || 'test@example.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD || 'testpassword';

// Helper function to log in
async function login(page) {
  await page.goto(`${BASE_URL}/login`);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(3000); // Allow Flutter to render
  
  // Enable accessibility if present
  const accessibilityButton = page.locator('button:has-text("Enable accessibility")');
  if (await accessibilityButton.isVisible({ timeout: 5000 }).catch(() => false)) {
    await accessibilityButton.click();
    await page.waitForTimeout(2000);
  }
  
  // Wait for app to load - look for common Flutter elements
  await page.waitForSelector('input, .mdc-text-field__input, [data-semantics-role]', { timeout: 20000 });
  
  // Email input - try Material Design selectors first
  let emailInput;
  try {
    emailInput = page.locator('.mdc-text-field__input').first();
    await emailInput.waitFor({ state: 'visible', timeout: 5000 });
  } catch {
    try {
      emailInput = page.locator('input[type="email"], input[placeholder*="email" i]');
      await emailInput.waitFor({ state: 'visible', timeout: 5000 });
    } catch {
      emailInput = page.locator('input').first();
      await emailInput.waitFor({ state: 'visible', timeout: 5000 });
    }
  }
  await emailInput.fill(TEST_EMAIL);
  
  // Password input
  let passwordInput;
  try {
    passwordInput = page.locator('.mdc-text-field__input').nth(1);
    await passwordInput.waitFor({ state: 'visible', timeout: 5000 });
  } catch {
    try {
      passwordInput = page.locator('input[type="password"]');
      await passwordInput.waitFor({ state: 'visible', timeout: 5000 });
    } catch {
      passwordInput = page.locator('input').nth(1);
      await passwordInput.waitFor({ state: 'visible', timeout: 5000 });
    }
  }
  await passwordInput.fill(TEST_PASSWORD);
  
  // Login button
  let loginButton;
  try {
    loginButton = page.locator('.mdc-button:has-text("Login"), button:has-text("Login")');
    await loginButton.waitFor({ state: 'visible', timeout: 5000 });
  } catch {
    loginButton = page.locator('button').filter({ hasText: /login/i }).first();
    await loginButton.waitFor({ state: 'visible', timeout: 5000 });
  }
  await loginButton.click();
  
  await page.waitForURL('**/home**', { timeout: 10000 });
}

// Test suite for Mix & Mingle QA pipeline
test.describe('Mix & Mingle QA Pipeline', () => {
  test.setTimeout(60000); // 60 seconds timeout

  test('Room creation - assert room title appears', async ({ page }) => {
    // Skip login for now - assume user is authenticated or test features directly
    await page.goto(`${BASE_URL}/home`);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(5000); // Allow app to load

    // If redirected to login, the test will fail, but let's see if /home renders
    // Navigate to create room - try multiple strategies
    let createRoomButton;
    try {
      createRoomButton = page.locator('button:has-text("Create Room")').first();
      await createRoomButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        createRoomButton = page.locator('button').filter({ hasText: /create.*room/i }).first();
        await createRoomButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Create Room button not found - app may not be rendering or user not authenticated');
      }
    }
    
    await createRoomButton.click();

    // Fill room details - try multiple strategies for inputs
    const roomTitle = `Test Room ${Date.now()}`;
    
    // Room name input
    let roomNameInput;
    try {
      roomNameInput = page.locator('input[placeholder*="Room name"]').first();
      await roomNameInput.waitFor({ timeout: 5000 });
    } catch {
      try {
        roomNameInput = page.locator('input').filter({ hasText: /name/i }).first();
        await roomNameInput.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Room name input not found');
      }
    }
    await roomNameInput.fill(roomTitle);
    
    // Description input
    let descriptionInput;
    try {
      descriptionInput = page.locator('textarea[placeholder*="Description"]').first();
      await descriptionInput.waitFor({ timeout: 5000 });
    } catch {
      try {
        descriptionInput = page.locator('textarea').first();
        await descriptionInput.waitFor({ timeout: 5000 });
      } catch {
        // Description might be optional, continue
        console.log('Description input not found, continuing...');
      }
    }
    if (descriptionInput) {
      await descriptionInput.fill('Test room description');
    }
    
    // Create button
    let createButton;
    try {
      createButton = page.locator('button:has-text("Create")').first();
      await createButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        createButton = page.locator('button').filter({ hasText: /create/i }).first();
        await createButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Create button not found');
      }
    }
    
    await createButton.click();

    // Wait for navigation to room
    await page.waitForURL('**/room**');

    // Assert room title appears
    const titleElement = page.locator(`text="${roomTitle}"`).first();
    await expect(titleElement).toBeVisible();

    console.log('✅ Room creation test passed: Room title appears');
  });

  test('Participant count - assert it updates after join', async ({ page }) => {
    await login(page);

    // Find an existing room or create one
    await page.goto(`${BASE_URL}/home`);
    
    // Wait for rooms to load
    await page.waitForTimeout(2000);
    
    const roomCard = page.locator('.room-card').first();
    await expect(roomCard).toBeVisible();

    // Get initial participant count
    let initialCountText;
    try {
      initialCountText = await roomCard.locator('.participant-count').textContent();
    } catch {
      try {
        initialCountText = await roomCard.locator('[class*="participant"]').textContent();
      } catch {
        initialCountText = await roomCard.locator('text').filter({ hasText: /\d+/ }).first().textContent();
      }
    }
    
    const initialCount = parseInt(initialCountText.replace(/\D/g, '')) || 0;

    // Join the room - try multiple strategies
    let joinButton;
    try {
      joinButton = roomCard.locator('button:has-text("Join")').first();
      await joinButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        joinButton = roomCard.locator('button').filter({ hasText: /join/i }).first();
        await joinButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Join button not found in room card');
      }
    }
    
    await joinButton.click();

    // Wait for room page
    await page.waitForURL('**/room**');

    // Check updated count (should be at least initial + 1)
    let updatedCountText;
    try {
      updatedCountText = await page.locator('.participant-count').textContent();
    } catch {
      try {
        updatedCountText = await page.locator('[class*="participant"]').textContent();
      } catch {
        updatedCountText = await page.locator('text').filter({ hasText: /\d+/ }).first().textContent();
      }
    }
    
    const updatedCount = parseInt(updatedCountText.replace(/\D/g, '')) || 0;

    if (updatedCount <= initialCount) {
      throw new Error(`Participant count did not update. Initial: ${initialCount}, Updated: ${updatedCount}`);
    }

    console.log('✅ Participant count test passed: Count updated from', initialCount, 'to', updatedCount);
  });

  test('Messaging - assert sent message displays in chat', async ({ page }) => {
    await login(page);

    // Join a room
    await page.goto(`${BASE_URL}/home`);
    await page.waitForTimeout(2000);
    
    const roomCard = page.locator('.room-card').first();
    await expect(roomCard).toBeVisible();
    
    let joinButton;
    try {
      joinButton = roomCard.locator('button:has-text("Join")').first();
      await joinButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        joinButton = roomCard.locator('button').filter({ hasText: /join/i }).first();
        await joinButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Join button not found in room card');
      }
    }
    
    await joinButton.click();
    await page.waitForURL('**/room**');

    // Send a message - try multiple strategies for input
    const testMessage = `Test message ${Date.now()}`;
    
    let messageInput;
    try {
      messageInput = page.locator('input[placeholder*="Type a message"]').first();
      await messageInput.waitFor({ timeout: 5000 });
    } catch {
      try {
        messageInput = page.locator('input[placeholder*="message" i]').first();
        await messageInput.waitFor({ timeout: 5000 });
      } catch {
        try {
          messageInput = page.locator('input[type="text"]').last(); // Likely the message input
          await messageInput.waitFor({ timeout: 5000 });
        } catch {
          throw new Error('Message input not found');
        }
      }
    }
    
    await messageInput.fill(testMessage);
    
    // Send button
    let sendButton;
    try {
      sendButton = page.locator('button:has-text("Send")').first();
      await sendButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        sendButton = page.locator('button').filter({ hasText: /send/i }).first();
        await sendButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Send button not found');
      }
    }
    
    await sendButton.click();

    // Assert message appears in chat
    const messageElement = page.locator(`text="${testMessage}"`).first();
    await expect(messageElement).toBeVisible();

    console.log('✅ Messaging test passed: Sent message displays in chat');
  });

  test('Settings - assert changes persist after reload', async ({ page }) => {
    await login(page);

    // Navigate to settings - try multiple strategies
    let settingsButton;
    try {
      settingsButton = page.locator('button:has-text("Settings")').first();
      await settingsButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        settingsButton = page.locator('button').filter({ hasText: /settings/i }).first();
        await settingsButton.waitFor({ timeout: 5000 });
      } catch {
        try {
          settingsButton = page.locator('[data-testid*="settings"], [aria-label*="settings" i]').first();
          await settingsButton.waitFor({ timeout: 5000 });
        } catch {
          throw new Error('Settings button not found');
        }
      }
    }
    
    await settingsButton.click();
    await page.waitForURL('**/settings**');

    // Change a setting (e.g., toggle notifications) - try multiple strategies
    let notificationToggle;
    try {
      notificationToggle = page.locator('input[type="checkbox"][name*="notification"]').first();
      await notificationToggle.waitFor({ timeout: 5000 });
    } catch {
      try {
        notificationToggle = page.locator('input[type="checkbox"]').first();
        await notificationToggle.waitFor({ timeout: 5000 });
      } catch {
        try {
          notificationToggle = page.locator('button').filter({ hasText: /notification/i }).first();
          await notificationToggle.waitFor({ timeout: 5000 });
        } catch {
          throw new Error('Notification toggle not found');
        }
      }
    }
    
    const wasChecked = await notificationToggle.isChecked();
    await notificationToggle.click();

    // Save settings - try multiple strategies
    let saveButton;
    try {
      saveButton = page.locator('button:has-text("Save")').first();
      await saveButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        saveButton = page.locator('button').filter({ hasText: /save/i }).first();
        await saveButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Save button not found');
      }
    }
    
    await saveButton.click();

    // Reload the page
    await page.reload();

    // Navigate back to settings
    try {
      settingsButton = page.locator('button:has-text("Settings")').first();
      await settingsButton.waitFor({ timeout: 5000 });
    } catch {
      try {
        settingsButton = page.locator('button').filter({ hasText: /settings/i }).first();
        await settingsButton.waitFor({ timeout: 5000 });
      } catch {
        throw new Error('Settings button not found after reload');
      }
    }
    
    await settingsButton.click();
    await page.waitForURL('**/settings**');

    // Assert the change persists
    const isNowChecked = await notificationToggle.isChecked();
    if (isNowChecked === wasChecked) {
      throw new Error(`Settings change did not persist after reload. Was checked: ${wasChecked}, Now checked: ${isNowChecked}`);
    }

    console.log('✅ Settings test passed: Changes persist after reload');
  });
});