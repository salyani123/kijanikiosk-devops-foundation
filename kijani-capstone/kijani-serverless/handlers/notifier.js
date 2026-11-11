const notify = async (event) => {
  for (const record of event.Records) {
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
    
    // Extract ID (e.g., from 'notify-ORD-001.json')
    const orderId = key.replace('notify-', '').replace('.json', '');

    const channel = process.env.NOTIFICATION_CHANNEL || 'log';

    console.log(JSON.stringify({
      service: 'kk-notifier', 
      event: 'notification.dispatched',
      orderId, 
      channel: channel,
      message: `Receipt successfully delivered for order ${orderId}`
    }));
  }
};

module.exports = { notify };