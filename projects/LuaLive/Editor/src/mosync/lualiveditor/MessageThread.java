package mosync.lualiveditor;

import java.util.concurrent.LinkedBlockingQueue;

@SuppressWarnings("unchecked")
public class MessageThread extends Thread
{
	private MessageQueue mMessageQueue;

	public MessageThread()
	{
		mMessageQueue = new MessageQueue();
	}

	public void postMessage(Message message)
	{
		mMessageQueue.postMessage(message);
	}

	public Message waitForMessage()
	{
		return mMessageQueue.nextMessage();
	}

	public static class Message
	{
		String mMessage;
		Object mObject;

		public Message(String message, Object object)
		{
			mMessage = message;
			mObject = object;
		}

		public String getMessage()
		{
			return mMessage;
		}

		public Object getObject()
		{
			return mObject;
		}
	}

	private static class MessageQueue
	{
		private LinkedBlockingQueue mMessageQueue = new LinkedBlockingQueue();

		public void postMessage(Message message)
		{
			mMessageQueue.offer(message);
		}

		public Message nextMessage()
		{
			try
			{
				return (Message) mMessageQueue.take();
			}
			catch (InterruptedException e)
			{
				return null;
			}
		}
	}
}
