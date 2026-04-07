import {
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*', // Cho phép Flutter kết nối từ bất kỳ đâu
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`🔌 Client kết nối: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`❌ Client ngắt kết nối: ${client.id}`);
  }

  @SubscribeMessage('send_message')
  handleMessage(@MessageBody() data: { sender: string; text: string }) {
    console.log('📩 Tin nhắn mới từ Flutter:', data);
    // Phát tin nhắn này đến TẤT CẢ mọi người đang online
    this.server.emit('receive_message', data);
  }
}c