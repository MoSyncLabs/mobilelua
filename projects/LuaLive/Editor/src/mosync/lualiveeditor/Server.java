package mosync.lualiveeditor;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;

public class Server extends MessageThread
{
	public static final int COMMAND_RUN_LUA_SCRIPT = 1;
	public static final int COMMAND_RESET = 2;
	public static final int COMMAND_REPLY = 3;

	private MainWindow mMainWindow;
	private boolean mRunning = false;
	private ArrayList<ClientConnection> mClientConnections;
	private SocketAcceptor mAcceptor;

	public Server(MainWindow mainWindow)
	{
		mMainWindow = mainWindow;
		mRunning = false;
		mClientConnections = new ArrayList<ClientConnection>();
		mAcceptor = new SocketAcceptor(this);
	}

	public void startServer()
	{
		if (!mRunning)
		{
			mRunning = true;
			start();
			mAcceptor.start();
			mMainWindow.showMessage("Server is running");
		}
	}

	private void stopServer()
	{
		mRunning = false;
		this.
		mAcceptor.close();
		mMainWindow.showMessage("Server stopped");
	}

	@Override
	public void run()
	{
		worker();
	}

	private void worker()
	{
		while (mRunning)
		{
			Message message = waitForMessage();

			Log.i("Server got message: " + message.getMessage());

			if ("ClientConnectionCreated".equals(message.getMessage()))
			{
				// Get connection object.
				ClientConnection connection = (ClientConnection) message.getObject();

				// Inform user that a new connection is opened.
				mMainWindow.showMessage("Client connected: " + connection.getHostName());

				// Add connection.
				Log.i("Client connected: " + connection.getHostName());
				mClientConnections.add(connection);

				// Start connection thread.
				connection.start();
			}
			else if ("ClientConnectionClosed".equals(message.getMessage()))
			{
				ClientConnection connection = (ClientConnection) message.getObject();
				mClientConnections.remove(connection);

				// Inform user that a client connection is closed.
				mMainWindow.showMessage("Client has disconnected: " + connection.getHostName());
			}
			else if ("CommandRunProgram".equals(message.getMessage()))
			{
				for (ClientConnection connection : mClientConnections)
				{
					Log.i("Sending CommandRunProgram to client connection: " + connection);
					connection.postMessage(
						new Message("CommandRunProgram", message.getObject()));
				}
			}
			else if ("CommandRunSelection".equals(message.getMessage()))
			{
				for (ClientConnection connection : mClientConnections)
				{
					Log.i("Sending CommandRunSelection to client connection: " + connection);
					connection.postMessage(
						new Message("CommandRunSelection", message.getObject()));
				}
			}
			else if ("CommandResetClient".equals(message.getMessage()))
			{
				for (ClientConnection connection : mClientConnections)
				{
					Log.i("Sending CommandResetClient to client connection: " + connection);
					connection.postMessage(
						new Message("CommandResetClient", message.getObject()));
				}
			}
			else if ("MessageFromClient".equals(message.getMessage()))
			{
				Log.i("MessageFromClient: " + message.getObject());
				mMainWindow.showMessage(message.getObject().toString());
			}
			else if ("CommandServerStop".equals(message.getMessage()))
			{
				stopServer();
			}
			else if("ServerAddressReceived".equals(message.getMessage()))
			{
				Log.i("ServerAddressReceived: " + message.getObject());
				mMainWindow.showMessage(message.getObject().toString());
			}
		}
	}

	static class SocketAcceptor extends Thread
	{
		private Server mServer;
		private ServerSocket mServerSocket;

		public SocketAcceptor(Server server)
		{
			mServer = server;
		}

		@Override
		public void run()
		{
			try
			{
				worker();
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}

		/**
		 * Call close to terminate the thread.
		 */
		public void close()
		{
			if (null != mServerSocket)
			{
				try
				{
					mServerSocket.close();
				}
				catch (IOException e)
				{
					e.printStackTrace();
				}
			}
		}

		public void worker() throws IOException
		{
			mServerSocket = new ServerSocket(55555);

			//Enumeration adapters = NetworkInterface.getNetworkInterfaces();
			//String a = "";
		    //if(adapters.hasMoreElements()) {
			//	a = adapters.nextElement().toString();
     		//}

			//mServer.postMessage(
			//		new Message("ServerAddressReceived", a));

			while (true)
			{
				Log.i("Waiting for client connection");
				Socket socket = mServerSocket.accept();
				Log.i("Client connection accepted");
				ClientConnection clientConnection = new ClientConnection(socket, mServer);
				mServer.postMessage(
					new Message("ClientConnectionCreated", clientConnection));
			}
		}
	}

	static class ClientConnection extends MessageThread
	{
		private Socket mSocket;
		private Server mServer;
		private boolean mRunning;
		private String mHostName;

		public ClientConnection(Socket socket, Server server)
		{
			mSocket = socket;
			mServer = server;
			mRunning = true;
			mHostName = socket.getInetAddress().getHostName();
		}

		public String getHostName()
		{
			return mHostName;
		}

		@Override
		public void run()
		{
			try
			{
				// Start communication.
				worker();
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
			finally
			{
				// Post connection closed message.
				mServer.postMessage(
					new Message("ClientConnectionClosed", this));
			}
		}

		// TODO: Make two threads out of this method, one for processing
		// incoming messages and one for writing data to client.
		// Perhaps this is not really needed? Perhaps synchronous
		// responses are adequate?
		public void worker() throws IOException
		{
			OutputStream out = mSocket.getOutputStream();
			InputStream in = mSocket.getInputStream();

			while (mRunning)
			{
				// Wait for message.

				Log.i("Waiting for message in client connection: " + getHostName());
				Message message = waitForMessage();
				Log.i("ClientConnectionMessage: " + message.getMessage());

				if ("CommandResetClient".equals(message.getMessage()))
				{
					// Send reset request to client.

					// Write command integer.
					writeIntToStream(out, COMMAND_RESET);

					// Write the size of the data, this is 0 bytes,
					// since the message contains no data.
					writeIntToStream(out, 0);

					out.flush();
				}
				else if ("CommandRunProgram".equals(message.getMessage())
					|| "CommandRunSelection".equals(message.getMessage()))
				{
					// Send run script request to client.

					// Write command integer.
					writeIntToStream(out, COMMAND_RUN_LUA_SCRIPT);

					// Write data size length.
					String string = message.getObject().toString();
					byte[] byteString = string.getBytes("ISO-8859-1");
					int dataSize = byteString.length;
					writeIntToStream(out, dataSize);

					Log.i("ClientConnection: out dataSize: " + dataSize);


					// Write script data.
					out.write(byteString);

					out.flush();
				}

				// Wait for result.
				// TODO: Make this asynchronous? No wait?

				// TODO: We should change to a dynamically allocated buffer.
				int bufSize = 100 * 1024;
				byte[] buffer = new byte[bufSize];
				int numBytesRead = 0;

				// Read data.
				numBytesRead += in.read(buffer);

				// Make sure that the header bytes are read.
				while (numBytesRead < 8)
				{
					numBytesRead += in.read(
						buffer,
						numBytesRead,
						bufSize - numBytesRead);
				}

				// Get total size of the message. The size of the data
				// is in the second integer.
				int dataSize = readIntFromByteBuffer(buffer, 4);
				int messageSize = 8 + dataSize;

				// Read remaining bytes.
				while (numBytesRead < messageSize)
				{
					numBytesRead += in.read(
						buffer,
						numBytesRead,
						bufSize - numBytesRead);
				}

				// First integer is the command.
				int command = readIntFromByteBuffer(buffer, 0);

				Log.i("ClientConnection: in dataSize: " + dataSize);
				Log.i("ClientConnection: in messageSize: " + messageSize);
				Log.i("ClientConnection: in command: " + command);

				switch (command)
				{
					case COMMAND_REPLY:
						// Read reply string. The reply starts at byte 8.
						String data = new String(buffer, 8, dataSize, "ISO-8859-1");

						Log.i(
							"numRead: " + numBytesRead +
							" data: " + data);

						// Post result message to server.
						mServer.postMessage(new Message("MessageFromClient", data));

						break;
				}
			}
		}

		/**
		 * Write a 32-bit int to a stream.
		 */
		private void writeIntToStream(OutputStream out, int value)
			throws IOException
		{
			int b1 = (value) & 0xFF;
			int b2 = (value >> 8) & 0xFF;
			int b3 = (value >> 16) & 0xFF;
			int b4 = (value >> 24) & 0xFF;
			out.write(b1);
			out.write(b2);
			out.write(b3);
			out.write(b4);
		}

		/**
		 * Read a 32-bit int from a byte buffer.
		 */
		private int readIntFromByteBuffer(byte[] buffer, int index)
		{
			int i1 = buffer[index];
			int i2 = buffer[index + 1];
			int i3 = buffer[index + 2];
			int i4 = buffer[index + 3];
			return
				(i1) |
				(i2 << 8) |
				(i3 << 16) |
				(i4 << 24);
		}
	}
}


