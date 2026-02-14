import { HMSReactiveStore } from '@100mslive/hms-video-store';

// Initialize the 100ms SDK and expose it globally
console.log('🎥 Initializing 100ms SDK...');

// Create the reactive store
const hmsStore = new HMSReactiveStore();
hmsStore.triggerOnSubscribe(); // Call subscribers immediately on subscribe

// Get actions and notifications
const hmsActions = hmsStore.getActions();
const hmsNotifications = hmsStore.getNotifications();

// Expose to window for Flutter to access
window.hmsStore = hmsStore;
window.hmsActions = hmsActions;
window.hmsNotifications = hmsNotifications;
window.HMSReactiveStore = HMSReactiveStore;

console.log('✅ 100ms SDK initialized and exposed globally');
console.log('Available: window.hmsStore, window.hmsActions, window.hmsNotifications');

// Export for bundler (won't be used by Flutter but good practice)
export { hmsStore, hmsActions, hmsNotifications };
